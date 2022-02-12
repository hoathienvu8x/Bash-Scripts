# [Machine Learning: C++ Naive Bayes Classifier Example](https://medium.com/@dr.sunhongyu/machine-learning-c-naive-bayes-classifier-example-dbe7b88a999b)

Naive Bayes classifier is an important basic model frequently asked in Machine Learning engineer interview.

What does Naive Bayes do?

Given a dataset with Classes (Labels) C and their Features/Attributes x, create a model that can predict the Label Class C with a set of Attributes x.

![](https://miro.medium.com/max/948/1*OleMEzkI3QZJ68oXKLCGNA.jpeg)

> Probabilistic model

Why called Naive?

All features are assumed to be independent when predicting the label, which is over-simplified assumption. In reality, this might be never true.

How to train this model?

- Basically it is a statistics aggregation process for counting all training entries per class label and per attribute.
- Calculate P(C) and P(x|C)

How to inference this model?

Based on maximum likelihood estimation process, get the largest

P(C|x) for all C labels.

![](https://miro.medium.com/max/1040/1*B84H0yidrAQ2FMaUW1dZcg.png)

> Inference of Naive Bayes Model

## Advantages

- Naive Bayes Algorithm is a fast, highly scalable algorithm.
- Naive Bayes can be use for Binary and Multiclass classification. It provides different types of Naive Bayes Algorithms like GaussianNB, MultinomialNB, BernoulliNB.
- It is a simple algorithm that depends on doing a bunch of counts.
- Great choice for Text Classification problems. It’s a popular choice for spam email classification.
- It can be easily train on small dataset

## Disadvantages

It considers all the features to be unrelated, so it cannot learn the relationship between features.

This example implementation is in C++. The model contains only 70 lines of code, and meant to use for study purpose or white-board coding.

```c++
class NaiveBayesClassifer {
    private:
        // <class id, class probility> <C, P(C)>
        unordered_map<int,double> classes;
        // <class id, <attribute id, probability>> <C, <x, P(x|C)>>
        unordered_map<int, unordered_map<int, double>> attributesPerClass;
    public:
        // input: vector< pair < class id, attribute id>> , DimSize is the number of attributes
        NaiveBayesClassifer(vector<vector<int>> &data, int DimSize) {
            // start training
            // count all classes and attributes
            for(auto entry : data) {
                if(classes.find(entry[0]) == classes.end()) {
                    classes[entry[0]] = 1;
                    unordered_map<int, double> pxc;
                    attributesPerClass[entry[0]] = pxc;
                } else {
                    classes[entry[0]] += 1;
                }
                for(int k = 1; k <= DimSize; k++) {
                    if(attributesPerClass[entry[0]].find(entry[k]) == attributesPerClass[entry[0]].end()) {
                        attributesPerClass[entry[0]][entry[k]] = 1;
                    } else {
                        attributesPerClass[entry[0]][entry[k]] += 1;
                    }
                }
            }
            // calculate probility per class and per attribute
            for(auto seg : attributesPerClass) {
                cout << " - - - Class " << seg.first << " - - - " << endl;
                for(auto entry : seg.second) {
                    entry.second /= classes[seg.first];
                    cout << "Attribute P(x=" << entry.first << "| C=" << seg.first << ") = " << entry.second << endl;
                }
                classes[seg.first] /= data.size();
                cout << "Class P(C=" << seg.first << ") = " << classes[seg.first] << endl;
            }
        }
        // predict class with attributes vector< attribute id>
        int predict(vector<int> attributes) {
            int maxcid = -1;
            double maxp = 0;
            for(auto cls : classes) {
                // p(C|x) = p(C)*p(x1|C)*p(x2|C)*...
                double pCx = cls.second;
                for(int i = 0; i<attributes.size();i++) {
                    pCx *= attributesPerClass[cls.first][attributes[i]];
                }
                if(pCx > maxp) {
                    maxp = pCx;
                    maxcid = cls.first;
                }
            }
            cout << "Predict Class: " << maxcid << " P(C|x) = " << maxp << endl;
            return maxcid;
        }
};
void populateData(vector<vector<int>> &data, unordered_map<string, int> &classmap, unordered_map<string, int> &attrimap, string c, string a1, string a2, int K) {
    vector<int> apair = {classmap[c],attrimap[a1], attrimap[a2]};
    vector<vector<int>> newarr(K, apair);
    data.insert(data.end(), newarr.begin(), newarr.end());
}

int main() {
    // prepare a training dataset with 2 attributes and 3 classes
    unordered_map<string, int> classmap = {
        { "apple", 0 },
        { "pineapple", 1 },
        { "cherry", 2 }
    };
    unordered_map<string, int> attrimap = {
        // color
        { "red", 0 },
        { "green", 1 },
        { "yellow", 2 },
        // shape
        { "round", 10 },
        { "oval", 11 },
        { "heart", 12 }
    };
    vector<vector<int>> data;
    populateData(data, classmap, attrimap, "apple", "green", "round", 20);
    populateData(data, classmap, attrimap, "apple", "red", "round", 50);
    populateData(data, classmap, attrimap, "apple", "yellow", "round", 10);
    populateData(data, classmap, attrimap, "apple", "red", "oval", 5);
    populateData(data, classmap, attrimap, "apple", "red", "heart", 5);
    populateData(data, classmap, attrimap, "pineapple", "green", "oval", 30);
    populateData(data, classmap, attrimap, "pineapple", "yellow", "oval", 70);
    populateData(data, classmap, attrimap, "pineapple", "green", "round", 5);
    populateData(data, classmap, attrimap, "pineapple", "yellow", "round", 5);
    populateData(data, classmap, attrimap, "cherry", "yellow", "heart", 50);
    populateData(data, classmap, attrimap, "cherry", "red", "heart", 70);
    populateData(data, classmap, attrimap, "cherry", "yellow", "round", 5);
    random_shuffle(data.begin(),data.end());
    // train model
    NaiveBayesClassifer mymodel(data, 2);
    // predict with model
    int cls = mymodel.predict({attrimap["red"],attrimap["heart"]});
    cout<<"Predicted class "<< cls <<endl;
    return 0;
}
```

Terminal Outputs:

```
- - - Class 1 - - -
Attribute P(x=1| C=1) = 0.318182
Attribute P(x=11| C=1) = 0.909091
Attribute P(x=2| C=1) = 0.681818
Attribute P(x=10| C=1) = 0.0909091
Class P(C=1) = 0.338462
- - - Class 0 - - -
Attribute P(x=1| C=0) = 0.222222
Attribute P(x=12| C=0) = 0.0555556
Attribute P(x=10| C=0) = 0.888889
Attribute P(x=0| C=0) = 0.666667
Attribute P(x=11| C=0) = 0.0555556
Attribute P(x=2| C=0) = 0.111111
Class P(C=0) = 0.276923
- - - Class 2 - - -
Attribute P(x=2| C=2) = 0.44
Attribute P(x=12| C=2) = 0.96
Attribute P(x=0| C=2) = 0.56
Attribute P(x=10| C=2) = 0.04
Class P(C=2) = 0.384615
Predict Class: 2 P(C|x) = 3230.77
Predicted class 2:Cherry
```
