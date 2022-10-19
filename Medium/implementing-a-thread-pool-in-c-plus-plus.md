---
title: "Implement Thread Pool in C++"
link: "https://www.cnblogs.com/sinkinben/p/16064857.html"
author: "sinkinben"
publish: "2022-03-27 22:11"
---

Implementing a thread pool is a producer-consumer problem:

- the `enqueue` function is the producer(s), it put some tasks into a queue.
- the threads in the pool are the consumers, they "eat" the tasks and finish them.

From the perspective of users, the thread pool here:

- has **fixed-number** of threads, each task in the queue has equal priority, and **each** task is a **lambda function**.
- It's easy to support priority scheduling, we can use `std::priority_queue` to replace `std::queue`.

The prerequisite knowledge:

- `std::thread`, `mutex`, `condition_variable`
- `std::future`
- `std::bind`
- `std::package_task`
- Universal references and perfect forwarding `std::forward<>`

## Source Code

```c++
#ifndef THREAD_POOL_H
#define THREAD_POOL_H
#include <functional>
#include <future>
#include <iostream>
#include <queue>
#include <thread>
#include <vector>

class ThreadPool
{
  public:
    ThreadPool(const ThreadPool &) = delete;
    ThreadPool(ThreadPool &&) = delete;
    ThreadPool &operator=(const ThreadPool &) = delete;
    ThreadPool &operator=(ThreadPool &&) = delete;

    ThreadPool(size_t nr_threads);
    virtual ~ThreadPool();

    template <class F, class... Args>
    std::future<std::result_of_t<F(Args...)>> enqueue(F &&f, Args &&...args);

  private:
    std::vector<std::thread> workers;
    std::queue<std::function<void()>> tasks;

    /* For sync usage, protect the `tasks` queue and `stop` flag. */
    std::mutex mtx;
    std::condition_variable cv;
    bool stop;
};
#endif
```

## dtor

```c++
ThreadPool::~ThreadPool()
{
    /* stop thread pool, and notify all threads to finish the remained tasks. */
    {
        std::unique_lock<std::mutex> lock(mtx);
        stop = true;
    }
    cv.notify_all();
    for (auto &worker : workers)
        worker.join();
}
```

## ctor

```c++
ThreadPool::ThreadPool(size_t nr_threads) : stop(false)
{
    for (size_t i = 0; i < nr_threads; ++i)
    {
        std::thread worker([this]() {
            while (true)
            {
                std::function<void()> task;
                /* pop a task from queue, and execute it. */
                {
                    std::unique_lock lock(mtx);
                    cv.wait(lock, [this]() { return stop || !tasks.empty(); });
                    if (stop && tasks.empty())
                        return;
                    /* even if stop = 1, once tasks is not empty, then
                     * excucte the task until tasks queue become empty
                     */
                    task = std::move(tasks.front());
                    tasks.pop();
                }
                task();
            }
        });
        workers.emplace_back(std::move(worker));
    }
}
```

In the ctor function, we should pay attention to:

```c++
cv.wait(lock, [this]() { return stop || !tasks.empty(); });
if (stop && tasks.empty()) return;
```

These two conditions means:

```
stop  tasks.empty  behavior
0     0            pop a task and execute
0     1            wait on cv
1     0            pop a task and execute
1     1            return, the thread end
```

Why not just call `cv.wait(lock, [this]() { return !tasks.empty(); })` ?

If we do this, it will cause such a case:

- All tasks have been completed, but all the threads will be waiting on `cv`.
- If `ThreadPool` leaves its scope and call `~ThreadPool()`, then `stop = 1`, `cv` will notify all threads in the pool.
- At such case, all threads wake up, but after then, they become waiting `cv` again, since `tasks.empty()` is true.
- The `ThreadPool` will get stuck at `worker.join()`.

## enqueue

Recall that we use `queue<function<void()>>` to store the tasks, i.e. each `task` in `tasks` is a lambda function, and it has no returned value and arguments.

But from the user's perspective, the `task` should have returned values and arguments.

Therefore, we should make a wrapper for the user's tasks. Package them (lambda functions) into `function<void()>`.

```c++
template <class F, class... Args>
std::future<std::result_of_t<F(Args...)>> ThreadPool::enqueue(F &&f, Args &&...args)
{
    /* The return type of task `F` */
    using return_type = std::result_of_t<F(Args...)>;
    
    /* wrapper for no arguments */
    auto task = std::make_shared<std::packaged_task<return_type()>>(
        std::bind(std::forward<F>(f), std::forward<Args>(args)...));

    std::future<return_type> res = task->get_future();
    {
        std::unique_lock lock(mtx);

        if (stop)
            throw std::runtime_error("The thread pool has been stop.");
        
        /* wrapper for no returned value */
        tasks.emplace([task]() -> void { (*task)(); });
    }
    cv.notify_one();
    return res;
}
```

Details explanation:

- `std::result_of_t<F(Args...)>` is to extract the returned type of function `F`.
- `std::bind(...)` generate a function with no argument. And we use `std::package_task` to generate a callable target.

However, why do we need `std::make_shared` in the outer wrapper?

Suppose we remove the `make_shared`, then we will write code like this:

```c++
auto task = std::package_task<return_type()>(std::bind(...));
auto future = task.get_future();
tasks.emplace([&]() -> void { task(); });
// or tasks.emplace([task]() -> void { task(); });
```

- For 1st method - pass by reference, once `enqueue` exited, the `task` variable will be invalid since it was stored on stack. So, when one thread got the `task`, the object `task` is invalid and not callable.
- For 2nd method - pass by value, according to [the document of](https://en.cppreference.com/w/cpp/thread/packaged_task) `std::package_task`, the copy-ctor and copy-operator `=` are deleted. So, this way will cause compiler-failures.

Therefore, we use `shared_ptr` to handle its life (more specifically, lengthen its life).

## Examples

**Example - 1**

```c++
/* tasks with returned value, no arguments */
void test1()
{
    /* Compute square of numbers. */
    ThreadPool pool(4);
    std::vector<std::future<int>> results;

    for (int i = 0; i < 8; ++i)
    {
        auto future = pool.enqueue([i] {
            std::this_thread::sleep_for(std::chrono::seconds(1));
            return i * i;
        });
        results.emplace_back(std::move(future));
    }

    for (auto &result : results)
        std::cout << result.get() << ' ';
    std::cout << std::endl;
}
```

**Example - 2**

```c++
bool isAscending(std::vector<int> &nums, int l, int r)
{
    for (int i = l; i + 1 < r; ++i)
        if (nums[i] > nums[i + 1])
            return false;
    return true;
}
/* tasks with returned values, and arguments. */
void test2()
{
    /* Multiple threads sorting */
    constexpr int N = 1e7;
    std::vector<int> nums(N);

    srand(time(nullptr));
    for (int i = 0; i < N; ++i)
        nums[i] = rand();

    ThreadPool pool(4);
    std::vector<std::future<std::pair<int, int>>> res;
    constexpr int step = N / 4;

    /* Sort numbers in range [l, r). */
    auto sort_task = [&nums](int l, int r) {
        std::sort(nums.begin() + l, nums.begin() + r);
        return std::pair{l, r};
    };

    for (int i = 0; i < 4; ++i)
    {
        auto future = pool.enqueue(sort_task, i * step, (i + 1) * step);
        res.emplace_back(std::move(future));
    }

    /* x.get() will wait for the completion of thread */
    for (auto& x : res)
    {
        auto [l, r] = x.get();
        assert(isAscending(nums, l, r));
        std::printf("Pass [%d, %d). \n", l, r); 
    }
}
```

Refer to: [https://github.com/progschj/ThreadPool](https://github.com/progschj/ThreadPool)
