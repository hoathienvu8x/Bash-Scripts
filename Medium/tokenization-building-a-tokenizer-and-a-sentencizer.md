# [Building a Tokenizer and a Sentencizer](https://medium.com/analytics-vidhya/tokenization-building-a-tokenizer-and-a-sentencizer-c19a00393c19)

## Understanding the underlying bones that give NLP its structure

![](https://miro.medium.com/max/1000/1*zVjT5Ryn9NchRdzmXn6EdA.png)

So we’ve learned about the many distinct steps that a Preprocessing Pipeline can take. If you’re coming from my previous article (or a NLP class), you probably have a general idea about what is **Tokenization **and what does it serve for. The purpose of this article is to help better clarify what is Tokenization, how it works and, most importantly, implement a Tokenizer.

If you came from my previous article, you might also be wondering about what happened to the “Bare String Preprocessing” step. The answer is that I wont be dedicating a full article about it, because it only includes a few functions that will be repeated more than once in future practical articles.

Now, back to Tokenization — this preprocessing step means transforming unstructured Natural Language input in something better structured (in computer terms). The main idea is to break the textual input into fragments that contain granular, yet useful data — these are called **Tokens**.

Tokenizing in essence means defining what is the boundary between Tokens. The simpler case is comprised of white space splitting. But that is not always the case — japanese and chinese, for example, use a different type of white space (that is not the default for most “split” functions). Also, there may be cases where characters other than white spaces can break a word in two tokens. Finally, there’s the case of deciding whether to divide or not special collocations such as bigrams and idioms (like “kicked the bucket” or “raining cats and dogs”) into individual tokens (which may “kick the bucket” of your processing).

Another step usually done together with Tokenizing is “ **Sentencizing**”. Or splitting input text into Sentences. This is very important if you have multiple sentences for each document. The main reason why it is important is related to parsing — you need to have the sentence (not the whole text) structure to define parts of speech, dependency relations etc. Sentencizing is a little more tricky than Tokenizing, since text structure is more free formed than sentence structure (I mean, not in morphological terms, but more in graphical terms).

As a word of caution, some tools create sentences **AFTER **tokenizing and parsing — this form of sentencizing takes into account not punctuation, but rather a series of morphological rules. This way, even if the words between two punctuation carry more than one sentence, these would get caught. Here’s a simple example: “John ate eggs and Mary ate potatoes” would become: [“John ate eggs”, “Mary ate potatoes”].

As mentioned and explained before, we’re going to do it all in Python and using English, the language that is common between me and you. I’ll try not to use any special third party tool, but I’ll follow a similar structure to how spaCy does tokenizing and sentencizing.

Enough chatting — time to get hands dirty (another idiom, my keyboard is clean, sir/ma’am!).

## Dummy Approach

We can start with a simpler approach that does the job without many details. We’re going to first create our DummySentencizer using Python OOP standards and some development good practices.

For that, we’ll organize our files starting from a ** *root ***folder (with the name of our project) and a inner ** *preprocessing* **folder, which will be home to all our preprocessing modules, including the ** *tokenization.py*** file that we’ll create. (later we’ll see that Tokenization is so important for NLP that we’ll have it in the *core *folder listed below). Here’s how it’ll be:

![](https://miro.medium.com/max/606/1*uSPU7EmhX1pPIwnWFqGkOw.png)

> File organization for the project. ‘core’ folder will be used later on on the full solution. If you’re not a python expert, the __init__.py is needed for module imports, so for now just create a blank file with this name.

In our ** *tokenization.py***, we create a DummySentencizer class. We’ll focus all the processing tasks in the constructor itself, meaning that just instantiating the class will give us a list of sentences. As constructor parameters, we’ll ask for the input text, the characters used for splitting and a delimiter token.

```python
class DummySentencizer:
   def __init__(self, input_text, split_characters=['.','?','!',':'], delimiter_token='<SPLIT>'):       
        self.sentences = []
        self.raw = str(input_text)
        self._split_characters=split_characters
        self._delimiter_token=delimiter_token
        self._index=0
        self._sentencize()
```

Our DummySentencizer will create a new sentence at every dot, exclamation mark, question mark or colons. The user can change that by providing a distinct list of characters, but we have a default.

Next, we provide a special “tag” ( *delimiter_token*) to divide our text. It’ll be appended to the punctuation marks so we can keeping them, since they can be useful in many cases. For that, we create a special “tag” that is not supposed to happen anywhere else (any character could be a text feature, so we can’t use one of those). This can also be replaced by user.

There are some other important details there: user accessible attributes are ** *sentences* **(which is a list that’ll keep the sentences after *sentencizing*) and ** *raw* **(which will keep the raw text, if the user needs it). Then, we have ** *_index***, which is a private attribute used to turn the object into an *iterable *(we’ll allow the user to do a “ *for*” in our DummySentencizer). Finally, we call the ** *_sentencize()*** function, which, you guessed it, will sentencize our raw input at instantiation!

```python
def _sentencize(self):
  work_sentence = self.raw
  for character in self._split_characters:
    work_sentence = work_sentence.replace(character, character+""+self._delimiter_token)
  self.sentences = [x.strip() for x in work_sentence.split(self._delimiter_token) if x !='']
```

The logic is simple: we make a copy of the raw data, we iterate all punctuation characters and add our special split token to them. Finally, we split the resulting string based on the special split token and clear trailing white spaces (that is what [x.strip() for x in …] does). We also avoid empty splits. Notice that reticence will be broken apart (this can be solved with regex).

To finish up, we override a couple magic methods to make our class iterable:

```python
def __iter__(self):
  return self
def __next__(self):
  if self._index < len(self.sentences):
      result = self.sentences[self._index]
      self._index+=1
      return result
  raise StopIteration
```

Our DummySentencizer is ready! Now that we can split our input strings into sentences, we can move to the DummyTokenizer. It’ll be very similar to our Sentencizer, with few modifications. In the same ** *tokenization.py***:

```python
import string
class DummyTokenizer:
  def __init__(self, sentence, token_boundaries=[' ', '-'], 
    punctuations=string.punctuation, delimiter_token='<SPLIT>'):
      self.tokens = []
      self.raw = str(sentence)
      self._token_boundaries = token_boundaries
      self._delimiter_token = delimiter_token
      self._punctuations = punctuations
      self._index = 0
      self._tokenize()
```

Once again we have a input text ( ** *sentence***), the delimiters ( ** *token_boundaries***, default to white space and hyphen), and the special “tag” ( ** *delimiter_token***). What about the ** *punctuations*** *? *It is provided to be used to sanitize punctuation, allowing them to be counted as tokens and separating them from connected words. We’re using python string module punctuation attribute (that’s why we have to add an import in the beginning), but you can provide a string or list of characters. Next, our _tokenize() method.

```python
def _tokenize(self):
  work_sentence = self.raw
  for punctuation in self._punctuations:
      work_sentence = work_sentence.replace(punctuation,
        " "+punctuation+" ")
  for delimiter in self._token_boundaries:
      work_sentence = work_sentence.replace(delimiter,
        self._delimiter_token)
  self.tokens = [x.strip() for x in work_sentence.split(self._delimiter_token) if x != '']
```

Very similar to our sentencize method, isn’t it? The difference here is that before adding the special split tags, we separate punctuation marks from connected strings (hence the replace for “ ”+punctuation+“ ”, which adds an extra white space before and after the punctuation).

The last part is the iterator part:

```python
def __iter__(self):
  return self
def __next__(self):
  if self._index < len(self.tokens):
    result = self.tokens[self._index]
    self._index+=1
    return result
  raise StopIteration
```

Simple, right?

But as you can imagine, this approach is not very smart. For example, if we input a decimal number (say, *19.3*), it’ll be broken into *[‘19’, ‘.’, ‘3']*. If we want a more complete approach, we’ll have to work harder!

Btw, if you’re thinking about stopping here, keep in mind that all this code is available in a Github project set up for this series. [Access it here](https://github.com/Sirsirious/NLPTools/tree/a2bda8fb7ad51a4d9ace6bc1eda9ea34ea23dec5)!

## A More Robust Approach

![](https://miro.medium.com/max/2000/1*-aOffdRHL0dIQae_7ivOVA.png)

We’ll now create a more robust approach. It is robust in the sense that we’ll have perdurable structures that can be reused for future steps in this series.

In this approach, we’ll create three classes: Document, Sentence and Token. Also, we’ll create two new static functions, our **tokenizer **and our **sentencizer**. These will differ from the early ones in the way they return the values: using instances of Tokens or Sentences, instead of lists of strings.

How will it work? We expect the user to start all the process by creating a Document class by passing it an input string. This process starts a chain reaction: the Document is set up, it calls the sentencizer to divide the document into sentences; next, when a Sentence is created, it calls the tokenizer to divide the sentence into tokens. At instantiating the Document, the user is actually doing the whole sentencizing/tokenizing part (Similar to what is done with spaCy, when the user does doc = nlp( *“String”*)).

In this part, I’ll focus on showing the structures and main variables. I’ll add a link to the commit done to create these structures so you can grasp the details (for example, I have overridden some magic methods to allow one to call a Sentence/Token by its index in a Document/Sentence and to loop over Document/Sentence elements).

The classes and the static functions are created inside **core/structures.py**.

![](https://miro.medium.com/max/594/1*7MlYZqIU3cFXMwk7t36iDQ.png)

> Here’s where we’re working. Dont worry about the test files or the __pycache__, I’ve just tried to follow some good practices to make a good tokenizer for you!

```python
class Document:
    def __init__(self, document_text):
        self.raw = document_text
        self.sentences = sentencize(self.raw)
        self._index = 0


#[...]


class Sentence:
    def __init__(self, start_position, end_position, raw_document_reference):
        self.start_pos = int(start_position)
        self.end_pos = int(end_position)
        self._document_string = raw_document_reference
        self.next_sentence = None
        self.previous_sentence = None
        self.tokens = tokenize(self._document_string[self.start_pos:self.end_pos])
        self._index = 0


#[...]


class Token:
    def __init__(self, start_position, end_position, raw_sentence_reference, SOS = False, EOS = False):
        self.start_pos = int(start_position)
        self.end_pos = int(end_position)
        self._sentence_string = raw_sentence_reference
        self.next_token = None
        self.previous_token = None
        self.SOS = SOS
        self.EOS = EOS
```

> Document, Sentence and Token classes

The biggest details here are the fact that a Sentence is extracted from the raw document by its start/end position in the Document, the same happening to Tokens. This could (with a little more tweaks) make us avoid storing the sentences and tokens as duplicate information in the memory, which in huge corpora can be a good plus (index search in a list is constant time, so no more computing complexity here if you’re worried).

**Document:** Our Document is created simply by the input of a raw string. Then it calls the **sentencize**. The _index there is for iterating, as in the Dummy approach.

**Sentence:** The Sentence is created with the “coordinates” of where it is located in the Document, the raw document string of where to search and some empty sentence references — these may be useful in a later time to navigate between sentences. Then, it calls the **tokenize**.

**Token:** For the Tokens, there’s not much of a difference to a sentence, but the fact that a token can be created as a SOS (for Start of Sentence) or EOS (for End of Sentence). Latter, we can also create other attributes, such as lemma or POS.

But, since we do not create a Sentence/Token with its own string, how to make comparisons, print them, etc? One way is to create a “get()” method that returns a string representation and use it in the class magic functions for comparison, printing, etc. Here’s the example for the Token class:

```python
#[...]
  def get(self):
      if self.SOS:
          return '<SOS>'
      elif self.EOS:
          return '<EOS>'
      else:
          return self._sentence_string[self.start_pos:self.end_pos]
# Displays the Token value in the terminal if the variable is called
  def __repr__(self):
      return self.get()
# Displays the Token value to the stdout
  def __str__(self):
      return self.get()
# Compares one token to other in a simple string-based fashion.
  def __eq__(self, other):
      return self.get() == other
```

> get() method and magic methods for Token Class.

Now comes the best part, the reasoning structure itself: the sentencize and tokenize functions.

But before, let us talk a little about an important topic in NLP (part of that ‘Bare String Preprocessing’ step I mentioned) — **Regular Expressions**.

Regular Expressions (Regex) is a way for matching specific expressions in a string of characters. A Regex engine uses a set of specific symbols to do lookups in a string and find patterns. These are very useful in NLP, since they can help us solve many problems without going deep in parsing. Since it looks for patterns, we can find information in documents using them. Imagine a purchase coupon — it contains the product, the quantity and the price (in many cases, at list) — we could look for the following patterns:

- Product name is composed of word characters [a-z, 0–9] and spaces.
- Quantity is usually a n-digit number [0–9] followed by a specific string [‘UN’, ‘LBS’, ‘OZ’, ‘KG’].
- Price is usually a decimal number preceded by a currency sign ($, ¢, £).

With **Regex**, you could find the price by looking for a pattern like this: ‘[$|£|¢]\d*\.\d*’ ([see an example here](https://regex101.com/r/WBweUl/1)). There are many distinct ‘tokens’ (or special ‘tags’ like \d for digits) to compose a pattern and Regex is a very complex topic by itself. I recommend you play with regex in an online engines, like as the awesome [regex101](https://regex101.com/).

I had to mention regex because it is the main resource that makes our “Robust” tokenizer and sentencizer distinct to the Dummy one. For that, I’ve created two series of patterns: one to detect sentence boundaries and one for escaping punctuation. They are presented as a package variable and passed as defaults to the tokenizer and sentencizer. Here are they:

```python
DEFAULT_SENTENCE_BOUNDARIES = ['(?<=[0-9]|[^0-9.])(\.)(?=[^0-9.]|[^0-9.]|[\s]|$)','\.{2,}','\!+','\:+','\?+']
"""
Breaking it down:
(?<=[0-9]|[^0-9.])(\.)(?=[^0-9.]|[^0-9.]|[\s]|$) -> looks for ant period that is not preceded or succeded by a digit or other period. 
This avoids the algorithm to split sentences at decimal numbers or reticences.
\.{2,} -> captures reticences.
\!+ -> captures series of exclamation points.
\:+ -> captures series of colons.
\?+ -> captures series of question marks.
"""


DEFAULT_PUNCTUATIONS = ['(?<=[0-9]|[^0-9.])(\.)(?=[^0-9.]|[^0-9.]|[\s]|$)','\.{2,}',
                        '\!+','\:+','\?+','\,+', r'\(|\)|\[|\]|\{|\}|\<|\>']


"""
The only difference here are in:
\,+ -> captures series of commas
\(|\)|\[|\]|\{|\}|\<|\> -> captures any parenthesis (the pipe | sign means 'or')
"""


# Another used regex is \s|\t|\n|\r -> it matches at any white char (\s), tab char (\t), new line char (\n) and carriage return char (\r)
```
> A brief explanation about the Regexes going to be used.

Now that we know our tools, let’s see how they act together:

```python
import re


#[...]


def sentencize(raw_input_document, sentence_boundaries = DEFAULT_SENTENCE_BOUNDARIES, delimiter_token='<SPLIT>'):
    working_document = raw_input_document
    punctuation_patterns = sentence_boundaries
    for punct in punctuation_patterns:
        working_document = re.sub(punct, '\g<0>'+delimiter_token, working_document, flags=re.UNICODE)
    list_of_string_sentences = [x.strip() for x in working_document.split(delimiter_token) if x.strip() != ""]
    list_of_sentences = []
    previous = None
    for sent in list_of_string_sentences:
        start_pos = raw_input_document.find(sent)
        end_pos = start_pos+len(sent)
        new_sentence = Sentence(start_pos, end_pos, raw_input_document)
        list_of_sentences.append(new_sentence)
        if previous == None:
            previous = new_sentence
        else:
            previous.next_sentence = new_sentence
            new_sentence.previous_sentence = previous
            previous = new_sentence
    return list_of_sentences
```

In the sentencize function, all the user needs to pass is the raw_input_document string. The rest is optional, being filled with our parameters and list of regexes. The first important step is to iterate over all our regexes for sentence boundaries and append our delimiter token to them so we can keep the punctuation while we split the document into sentences.

This is done using a special python module, the ** *re*** (for **R**egular **E**xpression), that has to be imported. We use the ** *sub*** * *function — it takes in three parameters: 1) the regex to match; 2) what to put in place of the match (we use a special regex token ‘\g<0>’, which takes the first group found and repeat it — this way we can keep the punctuation matched, even if it is a repetition of dots or exclamation marks); 3) the string to be treated. The final flag is just to avoid problems with unicode chars.

Next, we do the split and some juggling with references (we make a [linked list](https://www.geeksforgeeks.org/data-structures/linked-list/) with the sentences, filling those next_sentence and previous_sentence attributes) — this way, maybe we can benefit from **context **for reasoning in a later time, but this is all optional.

For the tokenize, there’s little difference:

```python
def tokenize(raw_input_sentence, join_split_text = True, split_text_char = '\-', punctuation_patterns= DEFAULT_PUNCTUATIONS, split_characters = r'\s|\t|\n|\r', delimiter_token='<SPLIT>'):
    working_sentence = raw_input_sentence
    #First deal with possible word splits:
    if join_split_text:
        working_sentence = re.sub('[a-z]+('+split_text_char+'[\n])[a-z]+','', working_sentence)
    #Escape punctuation
    for punct in punctuation_patterns:
        working_sentence = re.sub(punct, " \g<0> ", working_sentence)
    #Split at any split_characters
    working_sentence = re.sub(split_characters, delimiter_token, working_sentence)
    list_of_token_strings = [x.strip() for x in working_sentence.split(delimiter_token) if x.strip() !=""]
    previous = Token(0,0,raw_input_sentence, SOS=True)
    list_of_tokens = [previous]
    for token in list_of_token_strings:
        start_pos = raw_input_sentence.find(token)
        end_pos = start_pos+len(token)
        new_token = Token(start_pos,end_pos,raw_input_sentence)
        list_of_tokens.append(new_token)
        previous.next_token=new_token
        new_token.previous_token=previous
        previous=new_token
    if previous.SOS != True:
        eos = Token(len(raw_input_sentence), len(raw_input_sentence), raw_input_sentence, EOS=True)
        previous.next_token=eos
        eos.previous_token = previous
        list_of_tokens.append(eos)
    return list_of_tokens
```

First, we try to solve a problem I had in the past — in a corpus that I worked for my master’s (which was extracted from a PDF), there were several words broken by hyphens to make the “print” more human readable (but killing computer ‘processability’). There’s a regex substituting hyphens preceded by [a-z] and succeeded by new line characters [\n]. This, of course, is optional and can be disabled in the parameters.

Next, we do a similar thing to the punctuation, but instead of appending the split token, we add spaces to turn punctuation into tokens. Finally, for splitting, we do it for those special chars defined by regex. We have our tokens!

Of course, there’s more juggling here to make a token linked-list and to add SOS and EOS tokens (these can be useful in Transformer models, for example, but could also be turned optional).

Good, we have some robust functions! Let us test them?

Given that we have the Universal Declaration of Human Rights as ‘data.txt’ file, we can do a simple script to test (in this case, I’m considering each paragraph as a Document, but that could be different based on your needs — you could even make a “parahraphizer” :P).

```python
import pprint


declaration = []
with open('data.txt','r') as file:
  declaration+=file.readlines()


pp = pprint.PrettyPrinter(indent=2, compact=True)


for line in declaration:
  res = {'Document': line, 'Sentences':[]}
  document = Document(line)
  for sentence in document:
    res['Sentences'].append({'Sentence':sentence, 'Tokens':sentence.tokens})
  pp.pprint(res)
```

The results:

![](https://miro.medium.com/max/2000/1*YcUH9UetONeCgPFz0LZufw.png)

Great! The print is not so beautiful, but it works.

If you want to see what we’ve done so far but no future additions (so you can check the code), [go to this commit](https://github.com/Sirsirious/NLPTools/tree/e697af0f42894bebadc4edd4f2118aabe220cf77).

You can have the entire project in this GitHub repo: [https://github.com/Sirsirious/NLPTools](https://github.com/Sirsirious/NLPTools)

If you want to know more about how to do tokenizing in some specific tools, instead of spending time writing a tad more, see the post below, it is very complete and gives you a lot of possibilities to try with.

[ ## How to Get Started with NLP - 6 Unique Methods to Perform Tokenization ### Overview Looking to get started with Natural Language Processing (NLP)? Here's the perfect first step Learn how to… www.analyticsvidhya.com](https://www.analyticsvidhya.com/blog/2019/07/how-get-started-nlp-6-unique-ways-perform-tokenization/)

Now, if you want to know how spaCy deals with tokenizing in a more logical manner, check this other very interesting post by Edward Ma:

[ ## NLP Pipeline: Word Tokenization (Part 1) ### To tackle text related problem in Machine Learning area, tokenization is one of the common pre-processing. In this… medium.com](https://medium.com/@makcedward/nlp-pipeline-word-tokenization-part-1-4b2b547e6a3)

Finally, you can relate to spaCy docs itself:

[ ## Tokenizer · spaCy API Documentation ### class Segment text into words, punctuations marks etc. Segment text, and create Doc objects with the discovered segment… spacy.io](https://spacy.io/api/tokenizer/)

So we’re “done” with the Tokenizing part. Next up is stemming! How much fun can we have with it? [Let us check it out](https://medium.com/@tfduque/building-a-stemmer-492e9a128e84).
