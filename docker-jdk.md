[q#16137713](https://stackoverflow.com/q/16137713)
```java
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.ObjectInputStream;
import java.util.HashSet;
import java.util.Set;

public class Vocab {
    public static void main(String[] args) throws IOException {
        Set<String> VN_DICT = new HashSet<String>();
        try {
            String vocabPath = "vi-vocab";
            ObjectInputStream ois = new ObjectInputStream(new FileInputStream(vocabPath));
            VN_DICT = (Set<String>) ois.readObject();
            ois.close();
            // https://stackoverflow.com/a/12455755
            for (String s : VN_DICT) {
                System.out.println(s);
            }
        } catch (IOException | ClassNotFoundException e1) {
            e1.printStackTrace();
        }
    }
}

```

[a#16137745](https://stackoverflow.com/a/16137745)

```dockerfile
FROM alpine:3.7
USER root

RUN apk update
RUN apk fetch openjdk8
RUN apk add openjdk8
ENV JAVA_HOME=/usr/lib/jvm/java-1.8-openjdk
ENV PATH="$JAVA_HOME/bin:${PATH}"

RUN mkdir -p /home/VnCoreNLP
WORKDIR /home/VnCoreNLP
COPY vi-vocab .
COPY Vocab.java .

RUN javac Vocab.java
CMD java Vocab
```

```bash
docker build -t mrnhat/vnlp:v1 .
```

```bash
docker run --name vnlp -d -v /tmp:/home/VnCoreNLP -d mrnhat/vnlp:v1
```
