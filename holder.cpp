/* https://stackoverflow.com/a/13462096 */
class Holder {
public:
    enum Type {
        BOOL,
        INT,
        STRING,
        // Other types you want to store into vector.
    };

    template<typename T>
    Holder (Type type, T val);

    ~Holder () {
        // You want to properly destroy
        // union members below that have non-trivial constructors
    }

    operator bool () const {
        if (type_ != BOOL) {
           throw SomeException();
        }
        return impl_.bool_;
    }
    // Do the same for other operators
    // Or maybe use templates?

private:
    union Impl {
        bool   bool_;
        int    int_;
        string string_;

        Impl() { new(&string_) string; }
    } impl_;

    Type type_;

    // Other stuff.
};
