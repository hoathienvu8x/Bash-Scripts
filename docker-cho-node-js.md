# Cách tạo một Docker đơn giản cho Node.JS

![](https://topdev.vn/blog/wp-content/uploads/2019/09/5-696x365.jpg)

> Đây là một hướng dẫn ngắn và đơn giản về docker, khá hữu ích cho các anh em Nodejs.

## Tại sao bạn nên sử dụng Docker?

Khi công việc kinh doanh cần tới nhiều ứng dụng web khác nhau, khi mà bây giờ framework hay ngôn ngữ lập trình chỉ là công cụ. Các công ty không bị giới hạn và có thể sử dụng bất kỳ ngôn ngữ nào cần. Vì vậy chúng ta cần có một môi trường mà nhiều ứng dụng khác nhau có thể chạy cùng nhau trên đó.

Virtual Machines (VM) cho phép chúng ta chạy nhiều app trên cùng 1 server. Nhưng cũng có hạn chế. Mỗi VM cần toàn bộ OS để chạy. Mỗi OS lại cần CPU, RAM,… để chạy, rồi nó cần patching và licensing, do đó làm tăng chi phí và khả năng phục hồi.

Google bắt đầu sử dụng mô hình container từ lâu để giải quyết các thiếu sót của mô hình VM. Về cơ bản thì mô hình container có nghĩa là nhiều container trên cùng một máy chủ sử dụng cùng một máy chủ, giải phóng CPU, RAM để có thể được sử dụng ở nơi khác.

## Nhưng nó giúp các lập trình viên như thế nào?

Nó đảm bảo môi trường development tương đồng với môi trường production với tất cả lập trình viên và tất cả máy chủ.

Bất kể ai có thể làm project chỉ trong vòng vài giây, không cần phải vật lộn với config, thiết lập thư viện, cài đặt dependency,...

Nói một cách đơn giản, Docker là một nền tảng cho phép chúng ta develop, deploy và run các ứng dụng với các container.

Quay lại một chút, hệ thống container trông như thể nào và nó khác với VM như thế nào?

![::cap::1.1 Khác biệt giữa VM và Docker](https://topdev.vn/blog/wp-content/uploads/2019/05/h78f2cogxmuo787ys5xy.png)

Như bạn có thể thấy host và tài nguyên được chia sẻ trong container nhưng không có trong VM.

## Cách sử dụng Docker?

Chúng ta cần làm quen với một số thuật ngữ, bạn có thể đọc thêm Docker là gì:

![::cap::1.2. Mô tả docker image và docker container](https://topdev.vn/blog/wp-content/uploads/2019/05/cs6q2qn2m0zvc9s3geg9-696x401.png)

Docker image: là một file thực thi có chứa những hệ điều hành được cắt giảm và tất cả các thư viện và cấu hình cần thiết để chạy ứng dụng. nó có nhiều lớp xếp chồng lên nhau và được biểu diễn dưới dạng một object đơn. Một docker image được tạo ra để sử dụng file docker, chúng ta sẽ bàn về nó sau.

Docker Container: Nó là một instance đang chạy của docker image. Có thể có nhiều container chạy từ cùng một docker image.

## Container hóa một ứng dụng Node.js đơn giản

Chúng ta sẽ thử container hóa một ứng dụng node.js rất đơn giản, và tạo 1 image:

### Ứng dụng Node.js của bạn

Hãy bắt đầu với việc tạo folder `my-node-app`

```
mkdir my-node-app  
cd my-node-app
```

Hãy tạo một server node đơn giản trong `index.js` và thêm dòng code bên dưới vào đó:

```js
//Load express module with `require` directive

var express = require('express')

var app = express()

//Define request response in root URL (/)  
app.get('/', function (req, res) {  
 res.send('Hello World!')  
})

//Launch listening server on port 8081  
app.listen(8081, function () {  
  console.log('app listening on port 8081!')  
})
```

và lưu file này vào trong folder `my-node-app`

Giờ chúng ta tạo một file `package.json` và thêm dòng code dưới này vào:

```json
{

    "name": "helloworld",  
    "version": "1.0.0",  
    "description": "Dockerized node.js app",  
    "main": "index.js",  
    "author": "",  
    "license": "ISC",  
    "dependencies": {  
      "express": "^4.16.4" 
    }
}
```

Ở điểm này bạn không cần cài đặt express hay npm trong máy chủ, vì hãy nhớ là dockerfile xử lý tất cả các thiết lập dependency, lib và cấu hình.

### DockerFile

Hãy tạo dockerfile và lưu nó trong folder `my-node-app`. File này không có extension và được đặt tên là `Dockerfile`. Tiếp tục thêm dòng code bên dưới vào dockerfile

```
# Dockerfile  
FROM node:8  
WORKDIR /app  
COPY package.json /app  
RUN npm install  
COPY . /app  
EXPOSE 8081  
CMD node index.js
```

Giờ chúng ta đang làm gì ở đây nào

`FROM node:8` - pull docker image node.js từ docker hub, bạn có thể tìm ở đây `https://hub.docker.com/_/node/`

`WORKDIR /app` - cái này đặt thư mục làm việc cho code của chúng ta trong image, nó được sử dụng bằng tất cả các lệnh tiếp theo như `COPY`, `RUN` và `CMD`.

`COPY package.json /app` - cái này copy package.json từ host folder `my-node-app` đến image trong folder `/app`

`RUN npm install` - chúng ta chạy lệnh này trong image để cài đặt dependency (node_modules) cho app.

`COPY . /app` - Chúng ta báo với docker để copy file từ folder `my-node-app` và dán nó vào `/app` trong docker image.

`EXPOSE 8081` - Chúng ta đang mở cổng trên container bằng lệnh này. Tại sao lại có cổng này? Vì trong server, `index.js` listen cổng `8081`. Theo mặc định container được tạo từ image sẽ bỏ qua tất cả các request thực hiện cho nó.

### Build Docker Image

Mở terminal, đến folder `my-node-app` và gõ dòng lệnh sau:

```
# Build a image docker build -t <image-name> <relative-path-to-your-dockerfile>

docker build -t hello-world .
```

Dòng lệnh này tạo một image có nội dung `hello-world` vào host của chúng ta.

`-t`được sử dụng để đặt tên cho image, mà ở đây là hello-word

`.`là đường dẫn đến tệp docker, vì chúng ta đang trong thư mục `my-node-app`, nên sử dụng dấu chấm để thể hiện đường dẫn đến file docker.

Bạn sẽ thấy một output trong dòng lệnh giống thế này:

```
Sending build context to Docker daemon  4.096kB  
Step 1/7 : FROM node:8  
 ---> 4f01e5319662  
Step 2/7 : WORKDIR /app  
 ---> Using cache  
 ---> 5c173b2c7b76  
Step 3/7 : COPY package.json /app  
 ---> Using cache  
 ---> ceb27a57f18e  
Step 4/7 : RUN npm install  
 ---> Using cache  
 ---> c1baaf16812a  
Step 5/7 : COPY . /app  
 ---> 4a770927e8e8  
Step 6/7 : EXPOSE 8081  
 ---> Running in 2b3f11daff5e  
Removing intermediate container 2b3f11daff5e  
 ---> 81a7ce14340a  
Step 7/7 : CMD node index.js  
 ---> Running in 3791dd7f5149  
Removing intermediate container 3791dd7f5149  
 ---> c80301fa07b2  
Successfully built c80301fa07b2  
Successfully tagged hello-world:latest
```

Như bạn có thể thấy nó chạy các bước vào file docker và output một docker image. Có thể sẽ mất vài phút khi bạn thử lần đầu, nhưng từ lần tiếp theo sẽ bắt đầu sử dụng cache và build nhanh hơn nhiều với output cũng giống như trên. Bây giờ thử dòng lệnh bên dưới trong terminal để xem image của bạn có ở đó không nhé:

```
# Get a list of images on your host 
docker images
```

Sẽ có một list các image trong host của bạn, giống như thế này:

```
REPOSITORY    TAG      IMAGE ID      CREATED         SIZE  
hello-world   latest   c80301fa07b2  22 minutes ago  896MB
```

### Chạy Docker Container

Với image của chúng đã tạo, có thể tạo một container từ image này

```
# Default command for this is docker container run <image-name>  
docker container run -p 4000:8081  hello-world
```

Dòng lệnh này được sử dụng để chạy docker container

`-p 4000:8081`– Đây là lệnh cho phép, nó đánh dấu host 4000 sang cổng container 8081 mà chúng ta đã mở thông qua lệnh expose trong dockerfile. Bây giờ tất cả các request đến cổng host 4000 sẽ được chuyển thành cổng containter 8081

`hello-world` - Đây là tên chúng ta đặt cho image mới nhất khi chúng ta chạy lệnh docker-build

Bạn sẽ nhận một vài output giống thế này:

```
app listening on port 8081!
```

nếu bạn muốn truy cập vào container và gắn terminal bash vào nó, bạn có thể gõ

```
# Enter the container
docker exec -ti <container id> /bin/bash
```

Để kiểm tra container chạy chưa, mở terminal khác và gõ

```
docker ps
```

Bạn sẽ thấy container chạy như thế này

```
CONTAINER ID    IMAGE        COMMAND                  CREATED    
`<container id>`  hello-world  "/bin/sh -c 'node in..."   11 seconds ago

STATUS              PORTS                    NAMES  
Up 11 seconds       0.0.0.0:4000->8081/tcp   some-random-name
```

Nó nghĩa là container của chúng ta với id `<container id>` được tạo từ image hello-word, và được up lên và chạy theo cổng 8081.

Ứng dụng Node.js thông minh sẽ hoàn toàn được container hóa. Bạn có thể vào http://localhost:4000/ trên trình duyệt và thấy thế này:

![::cap::1.3 Ứng dụng Node.js đã được containerise](https://topdev.vn/blog/wp-content/uploads/2019/05/1_EvzalzRBmOZatvRui6j9yQ-696x199.png)

Và thế là bạn đã containerise ứng dụng đầu tiên của mình rồi đấy. Chúc các bạn thành công!

[Nguồn](https://topdev.vn/blog/docker-cho-node-js/?amp)
