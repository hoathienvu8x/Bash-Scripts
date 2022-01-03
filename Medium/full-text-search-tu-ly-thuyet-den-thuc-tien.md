# [Full Text Search, Từ Khái Niệm đến Thực Tiễn (Phần 1)](http://ktmt.github.io/blog/2013/10/27/full-text-search-engine/)

## Lời nói đầu

Là một lập trình viên mà đã từng phải thao tác với cơ sở dữ liệu, hay đơn thuần là đã từng là một trang web bán hàng ,chắc hẳn các bạn đã từng nghe qua về khái niệm “Full text search”. Khái niệm này đã được định nghĩa khá cụ thể và đầy đủ trên [wikipedia](http://en.wikipedia.org/wiki/Full_text_search). Nói một cách đơn giản, “Full text search” là kĩ thuật tìm kiếm trên “Full text database”, ở đây “Full text database” là cơ sở dữ liệu chứa “toàn bộ” các kí tự (text) của một hoặc một số các tài liệu, bài báo.. (document), hoặc là của websites. Trong loạt bài viết này, mình sẽ giới thiệu về Full Text Search, từ khái niệm đến ứng dụng thực tiễn của kĩ thuật này. Chuỗi bài viết không nhằm giúp bạn tìm hiểu cụ thể về Full Text Search technique trong MySQL, Lucene hay bất kì search engine nào nói riêng, mà sẽ giúp bạn hiểu thêm vầ bản chất của kĩ thuật này nói chung. Ở bài viết cuối cùng, mình sẽ cùng các bạn implement thử một “Full Text Search engine” sử dụng python, qua đó giúp các bạn nắm rõ hơn cốt lõi của vấn đề.

Trong phần đầu tiên mình sẽ giới thiệu về định nghĩa của Full text search, và khái niệm cơ bản nhất trong Full Text Search, đó là Inverted Index.

## Introduction

Chắc hẳn các bạn đã từng dùng qua một kĩ thuật tìm kiếm rất cơ bản, đó là thông qua câu lệnh **LIKE** của **SQL**.

```sql
SELECT column_name(s)
FROM table_name
WHERE column_name LIKE pattern;
```

Sử dụng **LIKE**, các bạn sẽ chỉ phải tìm kiếm ở column đã định trước, do đó lượng thông tin phải tìm giới hạn lại chỉ trong các column đó. Câu lệnh **LIKE** cũng tương đương với việc bạn matching pattern cho “từng” chuỗi của từng dòng (rows) của field tương ứng, do đó về độ phức tạp sẽ là tuyến tính với số dòng, và số kí tự của từng dòng, hay chính là “toàn bộ kí tự chứa trong field cần tìm kiếm”. Do đó sử dụng **LIKE** query sẽ có 2 vấn đề: - 1) Chỉ search được trong row đã định trươc - 2) Performance không tốt.

Như vậy chúng ta cần một kĩ thuật tìm kiếm khác, tốt hơn **LIKE** query, mềm dẻo hơn, tốt về performance hơn, đó chính là **Full text searching**.

## Cơ bản về kĩ thuật Full text search

Về mặt cơ bản, điều làm nên sự khác biệt giữa Full text search và các kĩ thuật search thông thường khác chính là “Inverted Index”. Vậy đầu tiên chúng ta sẽ tìm hiểu về Inverted Index

### Inverted Index là gì

Inverted Index là kĩ thuật thay vì index theo đơn vị row(document) giống như mysql thì chúng ta sẽ tiến hành index theo đơn vị term. Cụ thể hơn, Inverted Index là một cấu trúc dữ liệu, nhằm mục đích map giữa **term**, và các **document chứa term đó**

Hãy xem ví dụ cụ thể dưới đây, chúng ta có 3 documents D1, D2, D3

```
D1 = "This is first document"
D2 = "This is second one"
D3 = "one two"
```

Inverted Index của 3 documents đó sẽ được lưu dưới dạng như sau:

```
"this" => {D1, D2}
"is" => {D1, D2}
"first" => {D1}
"document" => {D1}
"second" => {D2}
"one" => {D2, D3}
"two" => {D3}
```

Từ ví dụ trên các bạn có thể hình dung được về thế nào là Inverted Index. Vậy việc tạo index theo term như trên có lợi thế nào? Việc đầu tiên là inverted index giúp cho việc tìm kiếm trên full text database trở nên nhanh hơn bao giờ hết. Hãy giả sử bạn muốn query cụm từ “This is first”, thì thay vì việc phải scan từng document một, bài toán tìm kiếm document chứa 3 term trên sẽ trở thành phép toán **union** của 3 tập hợp (document sets) của 3 term đó trong inverted index.

```
{D1, D2} union {D1, D2} union {D1} = {D1}
```

Một điểm lợi nữa chính là việc inverted index cực kì flexible trong việc tìm kiếm. Query đầu vào của bạn có thể là “This is first”, “first This is” hay “This first is” thì độ phức tạp tính toán của phép union kia vẫn là không đổi.

Như vậy chúng ta đã hiểu phần nào về khái niệm “Thế nào là Inverted Index”. Trong phần tiếp theo chúng ta sẽ tìm hiểu về cụ thể về cách implement của inverted index, và ứng dụng của inverted index vào việc tìm kiếm thông tin thông qua các kĩ thuật chính như: **tokenization technique** (thông qua N-Gram hoặc Morphological Analysis), **query technique** và **scoring technique**.

# [Full Text Search, Từ Khái Niệm đến Thực Tiễn (Phần 2)](http://ktmt.github.io/blog/2013/11/03/full-text-search/)

## Introduction

Trong phần 1, chúng ta đã tìm hiểu sơ qua về khái niệm Full Text Search, cũng như về Inverted Index. Qua bài viết đầu tiên, các bạn đã nắm được tại sao Inverted Index lại được sử dụng để tăng tốc độ tìm kiếm trong một “Full Text Database”. Đồng thời ở ví dụ của phần một, các bạn cũng đã thấy, để tạo ra Inverted Index thì các bạn phải tách được một string ra thành các **term**, sau đó sẽ index string đó theo term đã tách được. Chính vì thế việc **tách string**, hay còn gọi là **Tokenize** là một bài toán con quan trọng nằm trong bài toán lớn của Full Text Search. Ở bài này, chúng ta sẽ tìm hiểu về 2 kĩ thuật Tokenize cơ bản là:

- N-Gram
- Morphological Analysis

## N-gram

N-gram là kĩ thuật tokenize một chuỗi thành các chuỗi con, thông qua việc **chia đều** chuỗi đã có thành các chuỗi con đều nhau, có độ dài là `N`. Về cơ bản thì `N` thường nằm từ `1~3`, với các tên gọi tương ứng là `unigram(N==1)`, `bigram(N==2)`, `trigram(N==3)`. Ví dụ đơn giản là chúng ta có chuỗi “good morning”, được phân tích thành bigram:

```
"good morning" => {"go", "oo", "od", "d ", " m", "mo", "or", "rn", "ni", "in", "ng"}
```

Từ ví dụ trên các bạn có thể dễ dàng hình dung về cách thức hoạt động của N-gram. Để implement N-gram, chỉ cần một vài ba dòng code như sau, như ví dụ viết bằng python như sau:

```python
def split_ngram(self, statement, ngram):
    result = []
    if(len(statement) >= ngram):
      for i in xrange(len(statement) - ngram + 1):
        result.append(statement[i:i+ngram])
    return result
```

## Morphological Analysis

Morphological Analysis, rất may mắn có định nghĩa trên [wikipedia](https://vi.wikipedia.org/wiki/H%C3%ACnh_th%C3%A1i_h%E1%BB%8Dc_\(ng%C3%B4n_ng%E1%BB%AF_h%E1%BB%8Dc) bằng tiếng Việt. Định nghĩa khá dài dòng, các bạn có thể xem bằng [Tiếng Anh](http://en.wikipedia.org/wiki/Morphology_\(linguistics) Về cơ bản Morphological Analysis (từ bây giờ mình sẽ gọi tắt là MA), là một kĩ thuật phổ biến trong xử lý ngôn ngữ tự nhiên (Natural Language Processing). Morphological chính là “cấu trúc” của từ, như vậy MA sẽ là “phân tích cấu trúc của từ”, hay nói một cách rõ ràng hơn, MA sẽ là kĩ thuật tokenize mà để tách một chuỗi ra thành các từ có ý nghĩa. Ví dụ như cũng cụm từ “good morning” ở trên, chúng ta sẽ phân tích thành:

```
"good morning" => {"good", "morning"}
```

Để có được kết quả phân tích như trên, ngoài việc phải sở hữu một bộ từ điển tốt (để phân biệt được từ nào là có ý nghĩa, và thứ tự các từ thế nào thì có ý nghĩa), MA phải sử dụng các nghiên cứu sâu về xử lý ngôn ngữ tự nhiên, mà mình sẽ không đi sâu ở đây. Thông thường các công ty lớn sở hữu các search engine của riêng họ(như Yahoo, Google, Microsoft..) sẽ có các đội ngũ nghiên cứu để tạo ra nhiều bộ thư viện MA riêng của họ, thích hợp với nhiều ngôn ngữ. Ngoài ra chúng ta cũng có thể sử dụng các bộ thư viện được open source, hoặc sử dụng các package có sẵn trong các bộ full text search engine mà tiêu biểu là lucene.

## Mở rộng

Các bạn đọc đến đây chắc hẳn sẽ có suy nghĩ, để phân tách chuỗi, thì rõ ràng phân tích theo MA là quá hợp lý rồi, tại sao lại cần N-gram làm gì? Như mình đã nói ở trên, để xây dựng MA thì cần một bộ từ điển tốt, để giúp cho máy tính có thể phân biệt được các từ có nghĩa. Như thế nào là một từ điển tốt, thì về cơ bản, từ điển tốt là từ điển chứa càng nhiều từ (terms) càng tốt. Tuy nhiên ngôn ngữ thì mỗi ngôn ngữ lại có đặc trưng riêng, và không ngừng mở rộng, không ngừng thêm các từ mới. Việc chỉ sử dụng MA sẽ gây ra một tác dụng phụ là có rất nhiều từ không/chưa có trong từ điển, dẫn đến không thể index, và do đó sẽ không thể tiến hành tìm kiếm từ đó được.

Vậy cách giải quyết như thế nào? Cách giải quyết tốt nhất là chúng ta sẽ **kết hợp(hybrid)** cả MA và N-gram. Cách hybrid thế nào thì sẽ tuỳ vào ngôn ngữ/ hoàn cảnh sử dụng, và cả performance cần thiết nữa. Về cơ bản thì những từ nào khó/không có thể phân tích được bằng MA, thì chúng ta sẽ dùng N-gram.

## Kết luận

Qua bài viết lần này, các bạn đã hiểu thêm về 2 kĩ thuật tách từ (tokenize) cơ bản là N-gram và MA.

Sử dụng 2 kĩ thuật này như thế nào để index dữ liệu đầu vào, sẽ được giới thiệu trong các bài viết sắp tới.

# [Full Text Search, Từ Khái Niệm đến Thực Tiễn (Phần 3)](http://ktmt.github.io/blog/2014/01/04/full-text-search-engine-part-3/)

## Introduction

Trong phần 2, chúng ta đã nắm được một kĩ thuật cơ bản và quan trọng để tạo ra search-engine, đó chính là kĩ thuật tách chữ (Tokenize), thông qua 2 phương pháp chính là N-gram và Morphological Analysis. Nhờ có kĩ thuật này mà văn bản gốc sẽ được bóc tách thành các kí tự, sau đó sẽ được lưu trữ dưới dạng Inverted Index như đã giới thiệu ở phần 1.

Trong bài viết này, chúng ta sẽ tìm hiểu là làm thế nào, mà khi được cung cấp đầu vào là một chuỗi truy vấn (query string), search engine sẽ cung cấp được cho chúng ta kết quả phù hợp nhất. Về cơ bản, để tìm kiếm bên trong một khối dữ liệu khổng lồ đã được index dưới dạng “Inverted Index”, search-engine sẽ sử dụng “Boolean Logic”.

## Boolean Logic và tại sao Search Engine lại sử dụng Boolean Logic

Khi nhắc đến Boolean Logic, các bạn sẽ hình dung ra trong đầu những hình ảnh như thao tác AND/OR/XOR với bit, mạch logic trong điện tử số, hay biểu đồ ven. Đối tượng thao tác của Boolean Logic có thể là bit, cổng logic, hay là tập hợp (set). Trong bài này, Boolean Logic sẽ được nhắc đến với đối tượng là tập hợp (set), và hình ảnh dễ hình dung nhất khi thao tác với đối tượng này chính là biểu đồ Ven.

Để tìm hiểu mối liên quan giữa Boolean Logic và Search Engine, chúng ta hãy thử hình dung cơ chế của Search Engine. Khi được cung cấp một chuỗi truy vấn (query string), việc đầu tiên Search Engine sẽ phải sử dụng Parser module để bóc tách chuỗi truy vấn này theo một **ngữ pháp** đã được qui định trước, để tạo thành các token sử dụng cho logic tìm kiếm. Việc sử dụng Parser này cũng giống như compiler hay intepreter sẽ sử dụng các cú pháp đã được định nghĩa trước của một ngôn ngữ bất kỳ để dịch một đoạn code ra mã máy hoặc là bytecode. Ngữ pháp qui định trước càng phức tạp, không chỉ dẫn đến việc parse chuỗi truy vấn trở nên phức tạp hơn, việc viết ra một câu truy vấn phức tạp hơn (ảnh hưởng đến người dùng), mà còn khiến logic tìm kiếm cũng trở nên phức tạp, qua đó làm giảm hiệu suất của việc tìm kiếm. Chính vì thế mà việc tận dụng một ngữ pháp gần giống với Boolean Logic không những sẽ giúp giữ cho độ phức tạp khi parse query string ở mức thấp, mà nó còn giúp cho người dùng tạo ra những câu truy vấn dễ hiểu hơn.

## Sử dụng Boolean Logic trong Search Engine

Boolean logic sử dụng trong Search Engine thường sẽ gồm 3 phép toán chính là `AND`, `NOT` và `OR` Hãy trở lại ví dụ gần giống trong phần 1, chúng ta có 5 documents {D1, D2, D3, D4, D5} đã được index như sau:

```
D1 = "This is first document"
D2 = "This is second one"
D3 = "one two"
D4 = "This one is great"
D5 = "This two is great!"
```

```
"this" => {D1, D2, D4, D5}
"is" => {D1, D2, D4, D5}
"first" => {D1}
"document" => {D1}
"second" => {D2}
"one" => {D2, D3, D4}
"two" => {D3, D5}
```

Giả sử chúng ta muốn query một câu truy vấn như sau : “This one”. Sử dụng Morphological Analysis đã giới thiệu trong phần 2, chúng ta sẽ tách câu truy vấn đó thành 2 token là “This” và “one”. Bỏ qua yếu tố chữ hoa và chữ thường, thì “This” đã được index {D1, D2, D4, D5}, và “one” đã được index {D2, D3, D4}.

Thông thường để cho dễ hiểu và phù hợp với logic của người dùng, thì space sẽ tương đương với logic AND, hay là việc tìm kiếu “This one” sẽ tương đương với kết tìm kiếm “This” AND với kết quả tìm kiếm “one”. Hay như trong ví dụ này thì kết quả tìm kiếm sẽ là kết quả AND của 2 set {D1, D2, D4, D5} và {D2, D3, D4}. Kết quả này có thể thấy dễ dàng là {D2, D4}

Vậy nếu người dùng input là “This OR one” thì sao? Lúc này kết quả tìm kiếm sẽ là

```
{D1, D2, D4, D5} OR {D2, D3, D4} = {D1, D3, D5}
```

Từ ví dụ trên chúng ta thấy rằng độ phức tạp của việc tìm kiếm lúc này sẽ chuyển thành

```
Độ phức tạp của parse query string(1) 
+ Độ phức tạp của Index lookup(2) 
+ Độ phức tạp của thao tác boolean Logic dựa trên kết quả của Index lookup(3)
```

(1) thường sẽ không lớn do query string do user input khá ngắn, và trong trường hợp query string được generate phức tạp khi sử dụng lucene hoặc solr, thì việc sử dụng boolean logic rất đơn giản cũng làm độ phức tạp khi parse query string là không cao.

(2) Độ phức tạp của Index lookup tương đương với việc tìm kiếm giá trị của một key trong Hash table, chỉ khác là trên HDD, tuy nhiên so sánh với việc tìm kiếm trên BTree của MySQL thì performance của xử lý này là hoàn toàn vuợt trội.

(3) Thao tác này có thể được optimize rất nhiều dựa vào các lý thuyết tập hợp, hay các thư viện toán học cho big number.

Như vậy chúng ta có thể thấy bài toán tìm kiếm ban đầu đã được đưa về 3 bài toán nhỏ hơn, dễ optimize hơn.

## Kết luận

Bài viết đã giới thiệu về việc sử dụng Boolean Logic trong Full Text Search Engine. Qua đó các bạn chắc đã hình dung ra phần nào khi các bạn gõ một câu lệnh tìm kiếm vào ô tìm kiếm của Google, những gì sẽ xảy ra đằng sau (mặc dù trên thực tế những gì google làm sẽ phức tạp hơn rất nhiều).

## Tham khảo:

- [Make Findspot](http://gihyo.jp/dev/serial/01/make-findspot)

# [Full Text Search Từ Khái Niệm đến Thực Tiễn (Phần 4)](http://ktmt.github.io/blog/2014/03/03/full-text-search-tu-khai-niem-den-thuc-tien-phan-4/)

## Introduction

Trong phần 3, các bạn đã được tìm hiểu về việc sử dụng Boolean Logic để tìm ra các Document chứa các term trong query cần tìm kiếm. Vậy sau khi tìm được các Document thích hợp rồi thì chỉ việc trả lại cho người dùng, hay đưa lên màn hình? Bài toán sẽ rất đơn giản khi chỉ có 5, 10 kết quả, nhưng khi kết quả lên đến hàng trăm nghìn, thì mọi việc sẽ không đơn giản là trả lại kết quả nữa. Lúc đó sẽ có vấn đề mới cần giải quyết, đó là **đưa kết quả nào lên trước**, hay chính là bài toán về **Ranking**

Việc Ranking trong Full Text Search thông thường sẽ được thực hiện thông qua việc tính điểm các Document được tìm thấy, rồi Rank dựa vào điểm số tính được. Việc tính điểm thế nào sẽ được thực hiện thông qua các công thức, hay thuật toán, mà mình gọi chung là **Ranking Model**

## Ranking Model

Trong bài viết về Ranking news, mình đã nói về việc giải quyết một bài toán gần tương tự. Tuy nhiên bài toán lần này cần giải quyết khác một chút, đó là việc Ranking sẽ phải thực hiện dựa trên mối quan hệ giữa “query terms” và “document”.

Ranking Model được chia làm 3 loại chính: `Static`, `Dynamic`, `Machine Learning`. Dưới đây mình sẽ giới thiệu lần lượt về mỗi loại này.

## Static

Static ở đây có nghĩa là, Ranking Model thuộc loại này sẽ **không phụ thuộc** vào mối quan hệ ngữ nghĩa giữa “query term” và “document”. Tại sao không phụ thuộc vào “query term” mà vẫn ranking được? Việc này được giải thích dựa theo quan điểm khoa học là _độ quan trọng của document phụ thuộc vào mối quan hệ giữa các document với nhau_.

Chúng ta sẽ đi vào cụ thể một Ranking Model rất nổi tiếng trong loại này, đó chính là PageRank. PageRank là thuật toán đời đầu của Google, sử dụng chủ yếu cho web page, khi mà chúng có thể “link” được đến nhau. Idea của PageRank là “Page nào càng được nhiều link tới, và được link tới bởi các page càng quan trọng, thì score càng cao”. Để tính toán được PageRank, thì chúng ta chỉ cần sử dụng WebCrawler để crawl được mối quan hệ “link” giữa tất cả các trang web, và tạo được một Directed Graph của chúng.

Chính vì cách tính theo kiểu, tạo được Graph xong là có score, nên mô hình dạng này được gọi là “Static”.

Ngoài PageRank ra còn có một số thuật toán khác gần tương tự như HITS đã từng được sử dụng trong Yahoo! trong thời gian đầu.

## Dynamic

Ranking Model thuộc dạng Dynamic dựa chủ yếu vào **Mối quan hệ** giữa “query term” và “document”. Có rất nhiều thuật toán thuộc dạng này, có thuật toán dựa vào tần suất xuất hiện của “query term” trong document, có thuật toán lại dựa vào các đặc tính ngữ nghĩa (semantic) của query term , có thuật toán lại sử dụng những quan sát mang tính con người như thứ tự xuất hiện các từ trong “query term” và thứ tự xuất hiện trong “document”.

Một trong những thuật toán được sử dụng nhiều nhất là TF-IDF (Term Frequency Inverse Document Frequency). Thuật toán này dựa vào Idea là “query term” xuất hiện càng nhiều trong document, document sẽ có điểm càng cao.

Thuật toán này được biểu diễn dưới công thức sau

![](https://latex.codecogs.com/svg.image?TF-IDF(t,d,D)=TF(t,d)*IDF(t,D))

Ở đây t là query term, d là document cần được score, và D là tập hợp “tất cả” các documents. Trong đó thì:

![](https://latex.codecogs.com/svg.image?TF(t,d)=frequency(t,d))

![](https://latex.codecogs.com/svg.image?IDF(t,D)=\log\frac{N}{\left\|d\in&space;D:t\in&space;d\right\|})

Một cách đơn giản thì:

- TF : tần suất xuất hiện của term t trong document d
- IDF : chỉ số này biểu hiện cho tần suất xuất hiện của term t trong toàn bộ các documents. t xuất hiện càng nhiều, chỉ số càng thấp (vì xuất hiện quá nhiều đồng nghĩa với độ quan trọng rất thấp)

Công thức của TF-IDF đã phối hợp một cách rất hợp lý giữa tần suất của term và ý nghĩa/độ quan trọng của term đó.

Trong thực tế thì người ta hay sử dụng thuật toán Okapi BM25 hay gọi tắt là BM25, là một mở rộng của TF-IDF, nhưng thêm một vài weight factor hợp lý.

## Machine Learning

Ngoài việc sử dụng các mối quan hệ đơn giản giừa query term và document, hay giứa document với nhau, thì gần đây việc sử dụng học máy (Machine Learning) trong Ranking cũng đang trở nên rất phổ biến. Để nói về Machine Learning thì không gian bài viết này có lẽ là không đủ, mình sẽ nói về ý tưởng của Model này.

Idea của việc sử dụng Machine Learning trong ranking là chúng ta sẽ sử dụng một mô hình xác suất để tính toán. Cụ thể hơn là chúng ta sẽ sử dụng supervised learning, nghĩa là chúng ta sẽ có input là một tập dữ liệu X để training, một model M ban đầu, một hàm error để so sánh kết quả output X’ có được từ việc áp dụng model M vào query term, và một hàm boost để từ kêt quả của hàm error chúng ta có thể tính lại được model M. Việc này được lặp đi lặp lại mỗi lần có query, hoặc lặp lại một cách định kỳ (1 ngày 1 lần, 1 tháng 1 lần..) để model M luôn luôn được cải thiện.

Thuật toán gần đây được sử dụng khá nhiều trong Ranking model chính là Gradient Boosting Decision Tree mà các bạn có thể tham khảo ở [đây](https://www.cse.cuhk.edu.hk/irwin.king/_media/presentations/gbdt-tom.pdf)

## Conclusion

Bài viết đã giới thiệu về 3 mô hình chính dùng để Ranking kết quả tìm kiếm trong Full Text Search. Trong thực tế thì các công ty lớn nhưn Google, Yahoo, MS sẽ không có một mô hình cố định nào cả, mà sẽ dựa trên các kết quả có từ người dùng để liên tục cải thiện. Không có một mô hinh nào là “đúng” hay “không đúng” cả, mà để đánh giá Ranking Model chúng ta sẽ phải dựa trên thông kê người dùng (như click rate, view time…). Việc hiểu rõ Ranking Model sẽ giúp chúng ta build được một search engine tốt cho service của mình, đông thời cũng giúp ích rất nhiều cho việc SEO (Search Engine Optimization).

Tài liệu tham khảo: - [Yahoo! Learning to Rank Challenge Overview](http://jmlr.org/proceedings/papers/v14/chapelle11a/chapelle11a.pdf)

# [Full Text Search Từ Lý Thuyết đến Thực Tiễn (Phần Cuối)](http://ktmt.github.io/blog/2014/05/09/full-text-search-tu-ly-thuyet-den-thuc-tien-phan-cuoi/)

## Introduction

Trong loạt bài viết trước về Full-text search, mình đã giới thiệu về các khái niệm hết sức cơ bản để làm nên một search-engine:

- Phần 1: Giới thiệu cơ bản: Inverted Index
- Phần 2: Kỹ thuật Tokenize
- Phần 3: Tìm kiếm sử dụng Boolean Logic
- Phần 4: Các mô hình Ranking

Trong bài viết này, để khép lại loạt bài về Full-Text search, mình sẽ hướng dẫn cách làm một search engine hết sức đơn giản sử dụng inverted index. Sample code mình sẽ sử dụng Python để cho dễ hiểu.

## Code Design

Việc đầu tiên trước khi code chúng ta phải design xem chương trình của chúng ta sẽ gồm những module nào, nhiệm vụ mỗi module ra sao. Để design được thì chúng ta phải làm rõ yêu cầu bài toán và cách giải quyết.

Bài toán trong bài viết này là **xây dụng một search engine**. Để cho đơn giản chúng ta sẽ xây dựng search engine trên command line, dựa trên đầu vào là các documents với format được định nghĩa trước. Trong bài này, mình sẽ sử dụng một sample nhỏ của twitter data như là input documents. Bài toán được tóm tắt lại như dưới đây:

```
Input document:
11  superkarafan  superkarafan  http://twitter.com/superkarafan Yes. He is Kendo Kobayashi. One of great JKamilia RT "@nicolexrina:  Is your twitter DP you? I have seen him in ametalk before!"
12  sao_mama  saomama http://twitter.com/sao_mama @miwauknow  持って行きたいけど、北海道からだから重い(T_T)飲むゼリーとかはダメなのかな。「SMT」のときそうしたんだけど・・・

Command-line Interface:
./searcher <word>
```

Như đã giới thiệu ở loạt bài trước, Full Text Search sử dụng inverted index để lưu lại term và các document chứa term đó:

```
"this" => {D1, D2, D3, D4}
```

Vì vậy chúng ta cần một module để lưu Structure này, chúng ta sẽ gọi module đó là DocID. DocID sẽ có nhiệm vụ là lưu term và một array để chứa id của các documents mà chứa term đó.

Tuy nhiên chỉ lưu đơn thuần dữ liệu inverted index thì sẽ không đủ, chúng ta cần một module để lưu lại các document và ID của chúng để khi có kết quả tìm kiếm chúng ta có thể present kết quả dễ dàng hơn. Module này chúng ta sẽ gọi là Content. Content sẽ lưu lại Id và nội dung của document.

Chúng ta cũng sẽ cần một module để làm nhiệm vụ phân tích document ra thành các term như đã giới thiệu trong Bài 2: Kỹ thuật Tokenize. Chúng ta sẽ gọi module này là Tokenizer.

Đã có Tokenizer, DocID, Content, chúng ta cần một module sử dụng cả 3 module này để lưu trữ thông tin được tạo ra từ Tokenizer vào DocID và Content, chúng ta sẽ gọi nó là Indexer.

Cuối cùng, chúng ta cần một module sử dụng boolean logic như đã giới thiệu trong Bài 3 để tìm kiếm. Chúng ta sẽ gọi module này là Searcher. Module Searcher sẽ có nhiệm vụ sử dụng tách query ra thành các term, search ra một tập document chứa các term đó, và present ra màn hình.

Tóm tắt lại chúng ta sẽ có các module sau:

- DocID : Lưu inverted index
- Content : Lưu id và dữ liệu thô từ input data
- Tokenizer : Bóc tách term
- Indexer : Sử dụng tokenizer để lưu thông tin
- Searcher : Tìm kiếm

## Implement

Để implement bài toán này chúng ta sẽ sử dụng python. Chúng ta cũng cần một thư viện để lưu lại/sử dụng (dump) dữ liệu (inverted index) ra file. Python có một thư viện rất tốt để dump data structure ra file gọi là Pickle.

Sử dụng pickle, chúng ta sẽ lưu dữ liệu ra file và khi load chương trình lên sẽ sử load file vào data structure lên sau. Tách ra làm 2 bước như vậy giúp chúng ta tách biệt được 2 quá trình 1) Index và 2) Search, mà qua đó khi có thêm dữ liệu mới, index file sẽ được update thêm mà không ảnh hưởng đên Searcher.

Dưới đây chúng ta sẽ đi lần lượt vào implementation của từng module. Đầu tiên là DocID.

**DocID**

DocID - DocID.py

```python
import pickle

class DocID:
  def __init__(self):
    self.docIDTable = dict()

  def get_doc_num(self):
    return len(self.docIDTable)

  def set(self, term, docID, termPos):
    value = self.docIDTable.get(term, [])
    value.append((docID, termPos))
    self.docIDTable[term] = value

  def get(self, term):
    return self.docIDTable.get(term, [])

  def dump(self, file):
    f = open(file, "w")
    pickle.dump(self.docIDTable, f)
    f.close()

  def load(self, file):
    f = open(file)
    self.docIDTable = pickle.load(f)
    f.close()
```

Ở DocID chúng ta có property docIDTable được lưu dưới dạng dictionary của python, mà trong đó key là term , và value sẽ là array chứa Ids của các document chứa term đó. docIDTable chính là biểu diễn bằng code của inverted index data structure.

Module DocID có các hàm dump và load để lưu dữ liệu ra file và load dữ liệu lên memory. Tiếp theo chúng ta sẽ đến với implemetation của module Content.

**Content**

Content - Content.py

```python
import pickle

class Content:
  def __init__(self):
    self.contentTable = dict()

  def get_content_num(self):
    return len(self.contentTable)

  def set(self, content):
    self.contentTable[self.get_content_num()] = content
    current_index = self.get_content_num() - 1
    return current_index

  def get(self, id):
    return self.contentTable.get(id)

  ...
```

Module này chỉ nhằm nhiệm vụ lưu lại dữ liệu của document và Id của document đó. Việc này sẽ được thực hiện cũng qua dictionary của python, với key là Id của document, và value là content của document tương ứng.

Tiếp đến, module Tokenizer sẽ được implement như dưới đây

**Tokenizer**

Để cho đơn giản, tokenizer của chúng ta sẽ sử dụng ngram.

Tokenizer - Tokenizer.py

```python
class Tokenizer:
  def __init__(self, engine):
    self.engine = engine

  def split(self, statement, ngram):
    result = []
    if(len(statement) >= ngram):
      for i in xrange(len(statement) - ngram + 1):
        result.append(statement[i:i+ngram])
    return result
```

**Indexer**

Indexer - Indexer.py

```python
from docid import DocID
from content import Content
from tokenizer import Tokenizer


class Index:
  def __init__(self, ngram):
    self.tokenizer = Tokenizer("ma")
    self.docID = DocID()
    self.content = Content()
    self.ngram = ngram

  def tokenize(self, statement):
    return self.tokenizer.split(statement)

  def append_doc(self, token, id, pos):
    return self.docID.set(token, id, pos)

  def set_content(self, statement):
    return self.content.set(statement)

  def append(self, statement):
    tokenized_str = self.tokenize(statement)
    content_id = self.set_content(statement)

    token_index = 0

    for token in tokenized_str:
      self.append_doc(token, content_id, token_index)
      token_index += 1

  def dump(self, dir):
    f_content_name = "content.pickle"
    f_docid_name = "docid.pickle"
    self.content.dump(f_content_name)
    self.docID.dump(f_docid_name)

  def load(self, dir):
    f_content_name = "content.pickle"
    f_docid_name = "docid.pickle"

    self.content.load(f_content_name)
    self.docID.dump(f_docid_name)

def main(filepath, column):
  indexer = Index(NGRAM)
  f = codecs.open(filepath, "r", "utf-8")
  lines = f.readlines()

  for line in lines:
    print line
    elems = line.split("\t")
    indexer.append(''.join(elems[column-1]))

  f.close()
  indexer.dump("data/")
  return

if __name__ == "__main__":
  if len(sys.argv) < 3:
    print "usage: ./indexer.py INPUT_TSV_FILE_PATH TARGET_COLUMN_NUM"
    sys.exit(1)
  filepath = sys.argv[1]
  column = int(sys.argv[2])
  main(filepath, column)
```

Module này có nhiệm vụ là sử dụng Tokenizer để tách input document thành các term sử dụng ngram, tức là mỗi term sẽ có độ dài bằng độ dài ngram. Sau đó sẽ index term đó vào DocID, nếu term đó đã tồn tại thì id của document hiện tại sẽ được add vào docIDTable của docId thông qua hàm “set”.

Kết quả index sẽ được lưu vào file docid.pickle (inverted index data) và content.pickle (content data).

**Searcher**

Module này có nhiệm vụ load dữ liệu đã qua index từ 2 file docid.pickle và content.pickle vào memory, sau đó với mỗi query, Searcher sẽ phân tích query đó thành các term dựa vào tokenizer, tìm kiếm document chứa các term đó dựa vào dữ liệu từ docid, và present kết quả ra màn hình dựa vào dữ liệu lấy được từ content.pickle:

Searcher - Searcher.py

```python
from docid import DocID
from content import Content
from tokenizer import Tokenizer
from collections import Counter
import collections

class Searcher:
  def __init__(self, ngram, dir):
    self.docID = DocID()
    self.tokenizer = Tokenizer()
    self.content = Content()
    self.docID.load(dir + "docid.pickle")
    self.content.load(dir + "content.pickle")
    self.result = dict()

  def search(self, statement, numOfResult):
    tokenized_list = self.tokenizer.split_query(statement)
    return self._search(tokenized_list, numOfResult)

  def _search(self, tokenList, numOfResult):
    token_search_index = 0

    for token in tokenList:
      content_ids = self.docID.get(token)

      for content_id in content_ids:
        if not result[content_id]:
          self.result[content_id] = 0
        else:
          self.result[content_id] = result[content_id] + 1

  def print_result(self):
    sorted_result = sorted(self.result.items(), reverse=True)
    for item in sorted_result:
      print "{}\n".format(self.content.get(item))
```

Chúng ta có thể thấy Searcher là một module rất đơn giản sử dụng tokenizer để bóc tách query. Sau khi bóc tách query thành các term, với mỗi term chúng ta sẽ tìm các document chứa term đó dựa vào docID. Mỗi term chúng ta sẽ thu được một chuỗi Ids chứa id của document chứa chúng.

Để kết hợp các các chuỗi ids tìm được thành kết quả cuối cùng, chúng ta làm một mô hình ranking rất đơn giản, document nào chứa nhiều term hơn thì hiển thị trước. Logic này được thực hiện dựa vào tạo một dictionary chứa kết quả (self.result) , cứ mỗi khi tìm được document nào thì ta cộng kết quả thêm 1.

Kết quả cuối cùng sẽ được in ra màn hình thông qua hàm print_result. Như vậy chúng ta đã implement xong một search engine hết sức đơn giản.

## Conclusion

Thông qua chuỗi bài viết, chúng ta đã hiểu được phần nào việc tạo ra một search engine. Để có một search engine thành công, như google hay yahoo, không những performance phải được hoàn thiện ở mức tối đa với khối lượng dữ liệu rất lớn, thì việc có một mô hình ranking thích hợp cũng vô cùng quan trọng. Hy vọng chuỗi bài viết đã đem đến cho các bạn cái nhìn cơ bản nhất về search engine.
