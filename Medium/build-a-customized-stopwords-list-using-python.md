---
title: "Build A Customized Stopwords List Using Python"
link: "https://medium.com/analytics-vidhya/build-a-customized-stopwords-list-using-python-nlp-6fc78d4eae3c"
author: "Zahra Ahmad"
---

![](https://miro.medium.com/max/700/0*cvo-8P4TRDXMySOr)

> Photo by Sandy Millar on Unsplash

In this article, I will discuss how to build a customized stopword list using
python for your NLP application. This improves the performance if your data
is domain-specific.

## What is stopword list?

If we want to build some machine learning application and we want to make
sure that the algorithm will be able to provide accurate result, then stop
word list plays important role in this. Stopword is nothing but a list of
words which are not informative and these words do not have an important
role in contributing to the information.

According to Oxford dictionary

> Stopword is a word that is automatically omitted from a computer-generated
> concordance or index.

For example, if we take "to" as a stopword then "to eat apples" becomes
"eat apples" with out the word "to".

There are many applications in NLP that require stopwords so it is important
for you to maintain an up-to-date list in order for their algorithms work correctly.

## Why customized stopwords list?

In domain-specific data, the distribution of word frequency usually is different
from its distribution in general-domain data. For example, let’s assume that
you are building a document classification for web pages in an eCommerce
website, and in each page in your data you have some repeated words such as:

> Review the product.
> 
> Rate the product.
> 
> Contact us.
> 
> Available in stocks.

If you download NLTK stopwrods list, you can find words such as:

```
i
me
my
myself
we
our
ours
ourselves
you
your
yours

```

However, words like *review*, *rate*, *contact*, *available* and *stocks*
do not exit in the list. Since they are present in all pages (document)
of our data, apparently they do not give important information about the
class of the document. For that reason, it is better to remove them to
reduce the feature set and simplify the model.

However, I always recommend to use the default stopwords list from NLTK plus
the additional stopwords we will calculate from the dataset.

## How to Build the stopword list using Python NLTK library?

To build a stopword list in python, we will use sklearn library with the
following pipeline:

- **CountVectorizer**:

  This module in python takes a list of text (or column in a dataframe) and
produces a collection of text documents to a matrix of token counts.
  
  This means that for each item in the list, it will produce a list of words
in that item, and the count of each words in it.
  
  The output of this module after we fit it to our data is word_count as
shown in the code below. We call this count (term frequency) or TF.

- **TfidfTransformer**

  According to python sklearn documentation, Tf means term-frequency while
`tf-idf` means term-frequency times inverse document-frequency. This is a
common term weighting scheme in information retrieval, that has also found
good use in multiple NLP applications such as document classification and
text summarisation.

  The formula that is used to compute the `tf-idf` for a term `t` of `a`
document `d` in a document set is $tf-idf(t, d) = tf(t, d) * idf(t)$,
and the idf is computed as $idf(t) = log [ n / df(t) ] + 1$

  where `n` is the total number of documents in the document set and `df(t)`
is the document frequency of `t`; the document frequency is the number of
documents in the document set that contain the term `t`. The effect of adding
"1" to the idf in the equation above is that terms with zero idf, i.e.,
terms that occur in all documents in a training set, will not be entirely
ignored. (Note that the idf formula above differs from the standard textbook
notation that defines the idf as $idf(t) = log [ n / (df(t) ] + 1$.
[Ref](https://scikit-learn.org/stable/modules/generated/sklearn.feature_extraction.text.TfidfTransformer.html)

Now we are ready to put everything together and generate the list of words
according to their tfidf scores (note that we sort the words by setting
`ascending=True`, so they will be sorted from the least important (informative)
to the most informative ones.

Note that the code assumes that you have a panda dataframe (`df`) with the
column called (`text`), each row in that dataframe represents a document in
your collection.

```python
import pandas as pd
import numpy as np 
from sklearn.feature_extraction.text import CountVectorizer
from sklearn.feature_extraction.text import TfidfTransformer
from sklearn.feature_extraction.text import TfidfVectorizer


#using the count vectorizer
count = CountVectorizer()
word_count=count.fit_transform(df['text'])

tfidf_transformer=TfidfTransformer(smooth_idf=True,use_idf=True)
tfidf_transformer.fit(word_count)
df_idf = pd.DataFrame(
    tfidf_transformer.idf_,
    index=count.get_feature_names(),
    columns=["idf_weights"]
)


#inverse document frequency
df_idf.sort_values(by=['idf_weights'])

#tfidf
tf_idf_vector=tfidf_transformer.transform(word_count)
feature_names = count.get_feature_names()

first_document_vector=tf_idf_vector[1]
df_tfifd= pd.DataFrame(
    first_document_vector.T.todense(),
    index=feature_names,
    columns=["tfidf"]
)

df_tfifd.sort_values(by=["tfidf"],ascending=True)

```

## Manual assessment

After you generated the df_tfidf dataframe, it is very important to look
at the top N words and check them manually according to your needs and your
experience in the field so you do not mistakenly add informative words to
your list. The number of words is also your call in this task, however,
on average, we used in NLP to assume that we have around 40–60% stopwords
list of unique words, meaning if you have 100 unique words in your text,
40 to 60 words of them are stopwords. Of course this is in natural language
text, such as news or book text. If you have for example product titles,
the percentages drops significantly to something around 5%.
