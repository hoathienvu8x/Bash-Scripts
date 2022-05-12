---
title: How to add a background thread to a Flask app?
link: https://vmois.dev/python-flask-background-thread/
author: Vladyslav Moisieienkov
---

This short article covers a template for setting up a Flask based web app
with a background thread. Knowledge of Python and basic knowledge of Flask
is required.

## Introduction

Let’s use an example to demonstrate how to add a background thread to Flask app.

Imagine we have a Flask app that accepts some HTTP requests. During request
processing, we need to do some side tasks that take longer to run. We do
not want the user to wait until tasks are finished to receive a response.
In addition, we want to keep our app as simple as possible so we cannot use
dedicated software like Celery to run our long-running tasks. So, we decide
to set up a separate background Python thread alongside our Flask app.

## Setting up a background thread

The Flask-based web app will handle POST requests and submit long-running
tasks to our background thread. When we terminate the Flask app, the background
thread will have an opportunity to clean up its resources before stopping
(so-called _graceful shutdown_).

Our sample project contains two files:

- `background_thread.py`, where background thread is implemented;
- `app_factory.py`, Flask app.

Let’s first take a look at the `background_thread.py` file:

```python
import logging
import queue
import threading
import time
from queue import Queue
from abc import abstractmethod, ABC
from typing import Dict

TASKS_QUEUE = Queue()


class BackgroundThread(threading.Thread, ABC):
    def __init__(self):
        super().__init__()
        self._stop_event = threading.Event()

    def stop(self) -> None:
        self._stop_event.set()

    def _stopped(self) -> bool:
        return self._stop_event.is_set()

    @abstractmethod
    def startup(self) -> None:
        """
        Method that is called before the thread starts.
        Initialize all necessary resources here.
        :return: None
        """
        raise NotImplementedError()

    @abstractmethod
    def shutdown(self) -> None:
        """
        Method that is called shortly after stop() method was called.
        Use it to clean up all resources before thread stops.
        :return: None
        """
        raise NotImplementedError()

    @abstractmethod
    def handle(self) -> None:
        """
        Method that should contain business logic of the thread.
        Will be executed in the loop until stop() method is called.
        Must not block for a long time.
        :return: None
        """
        raise NotImplementedError()

    def run(self) -> None:
        """
        This method will be executed in a separate thread
        when start() method is called.
        :return: None
        """
        self.startup()
        while not self._stopped():
            self.handle()
        self.shutdown()


class NotificationThread(BackgroundThread):
    def startup(self) -> None:
        logging.info('NotificationThread started')

    def shutdown(self) -> None:
        logging.info('NotificationThread stopped')

    def handle(self) -> None:
        try:
            task = TASKS_QUEUE.get(block=False)
            # send_notification(task)
            logging.info(f'Notification for {task} was sent.')
        except queue.Empty:
            time.sleep(1)


class BackgroundThreadFactory:
    @staticmethod
    def create(thread_type: str) -> BackgroundThread:
        if thread_type == 'notification':
            return NotificationThread()

        # if thread_type == 'some_other_type':
        #     return SomeOtherThread()

        raise NotImplementedError('Specified thread type is not implemented.')

```

`BackgroundThread` inherits from the `threading.Thread` class to implement `startup`
and `shutdown` mechanism. It acts as a base abstract class.

All concrete implementations that contain a business logic like `NotificationThread`
inherit from `BackgroundThread` class.

To communicate to the thread that it needs to stop,
[`threading.Event`](https://docs.python.org/3/library/threading.html#threading.Event)
object is used. When the `stop` method is called, the internal flag of the
`self.stop_event` object is set to `True`. In the `run` method, the _while loop_
checks if `stop_event` is set and if yes, exits the loop.

`BackgroundThreadFactory` provides a convenient method to create different
kinds of threads. This is useful if you expect the number of thread types
to grow in the future. Otherwise, feel free to instantiate the background
thread directly.

Now, let’s take a look at the `app_factory.py` file which provides code for
setting up a Flask app:

```python
import os
import logging
import signal
from flask import Flask, request, jsonify

from background_thread import BackgroundThreadFactory, TASKS_QUEUE

logging.basicConfig(level=logging.INFO, force=True)


def create_app():
    app = Flask(__name__)

    @app.route('/task', methods=['POST'])
    def submit_task():
        task = request.json
        logging.info(f'Received task: {task}')

        TASKS_QUEUE.put(task)
        return jsonify({'success': 'OK'})

    notification_thread = BackgroundThreadFactory.create('notification')

    # this condition is needed to prevent creating duplicated thread in Flask debug mode
    if not (app.debug or os.environ.get('FLASK_ENV') == 'development') or os.environ.get('WERKZEUG_RUN_MAIN') == 'true':
        notification_thread.start()

        original_handler = signal.getsignal(signal.SIGINT)

        def sigint_handler(signum, frame):
            notification_thread.stop()

            # wait until thread is finished
            if notification_thread.is_alive():
                notification_thread.join()

            original_handler(signum, frame)

        try:
            signal.signal(signal.SIGINT, sigint_handler)
        except ValueError as e:
            logging.error(f'{e}. Continuing execution...')

    return app

```

The app and background thread will communicate via the Python `queue.Queue`
object called `TASKS_QUEUE`. A [queue](https://docs.python.org/3/library/queue.html)
is a simple thread-safe queue with put/get operations. New tasks will be
put to the queue by the Flask app, and the background thread will get them
from the queue and process.

> **Warning**: In case of an app restart, items in the `TASK_QUEUE` will be lost.
This is a simple implementation. If you have critical data, consider using
dedicated software like Celery.

When a program is terminated, the `SIGINT` signal is received, and, using
[signal](https://docs.python.org/3/library/signal.html) Python module, custom
handler, `sigint_handler`, is executed. Before adding a custom handler, the
original handler for the `SIGINT` signal is saved.

`sigint_handler` is stopping the background thread, waits until the thread
stops, and executes the original handler to properly exit the program.

> **Warning**: Graceful shutdown is not working in debug mode in Flask (when
`FLASK_ENV=development`). After a couple of hours of debugging, I still cannot
figure out why exactly. If I will ever do, expect updates to this article.

> **Warning**: The background thread will not be started when using `gunicorn`
with the environment variable `FLASK_ENV=development`.
