/** **************************************************************************************
*                                                                                        *
*    A Ridiculously Simple JSON Parser for C++ (JSONp-cpp)                                *
*    Version 2.x                                                                         *
*    ----------------------------------------------------------                          *
*    Copyright (C) 2018  Subhrajit Bhattacharya                                          *
*                                                                                        *
*    This program is free software: you can redistribute it and/or modify                *
*    it under the terms of the GNU General Public License as published by                *
*    the Free Software Foundation, either version 3 of the License, or                   *
*    (at your option) any later version.                                                 *
*                                                                                        *
*    This program is distributed in the hope that it will be useful,                     *
*    but WITHOUT ANY WARRANTY; without even the implied warranty of                      *
*    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the                       *
*    GNU General Public License for more details <http://www.gnu.org/licenses/>.         *
*                                                                                        *
*                                                                                        *
*    Contact:  subhrajit@gmail.com                                                       *
*              https://www.lehigh.edu/~sub216/ , http://subhrajit.net/                   *
*                                                                                        *
*                                                                                        *
*************************************************************************************** **/

#ifndef __DOSL_JSONPARSE_TCC
#define __DOSL_JSONPARSE_TCC

#include <stdio.h>
#include <stdlib.h>
#include <string>
#include <regex>
#include <vector>
#include <unordered_map>
#include <utility>
#include <iostream>
#include <climits>

namespace jsonlib {
    static char const* JSONobjectbrackets = "{}";
    static char const* JSONarraybrackets = "[]";
    static char JSONobjectassignment = ':';
    static char JSONarraydelimiter = ',';
    static std::vector<char const*> JSONbrackets = { JSONobjectbrackets, JSONarraybrackets };
    static std::vector<char const*> JSONstringquotes = { "\"\"", "''" };
    static char JSONcharescape = '\\';
    static std::string JSONlinecommentstart = "//";
    static std::string JSONprinttab = "    ";
    enum JSONType { JSON_UNINITIATED, JSON_UNKNOWN, JSON_OBJECT, JSON_ARRAY, JSON_LEAF };
    // ============================================================
    // Direct string manipulation functions
    inline
    std::string to_string (JSONType rt) {
        switch (rt) {
            case JSON_UNINITIATED: return("JSON_UNINITIATED");
            case JSON_UNKNOWN: return("JSON_UNKNOWN");
            case JSON_OBJECT: return("JSON_OBJECT");
            case JSON_ARRAY: return("JSON_ARRAY");
            case JSON_LEAF: return("JSON_LEAF");
        }
        return("JSON_UNKNOWN");
    }
    enum StrTrimDir { STRTRIM_L=1, STRTRIM_R=2, STRTRIM_LR=3 };
    inline
    bool is_number(const std::string &token) {
        return std::regex_match(token, std::regex("(\\+|-)?[0-9]*(\\.?([0-9]+))$"));
    }
    inline
    bool is_boolean(const std::string &token) {
        if (token.size() < 4) {
            return false;
        }
        return token == "true" || token == "false";
    }
    inline
    bool is_null(const std::string &token) {
        if (token.size() < 4) {
            return false;
        }
        return token == "null";
    }
    inline std::string strtrim (std::string str, std::string chars=" \t\n\r", int max_count=-1, StrTrimDir dirs=STRTRIM_LR) {
        if (str.empty()) return(str);
        if (max_count<0) max_count = str.length();
        if (dirs & STRTRIM_L) { // left trim
            int p;
            for (p=0; p<max_count; ++p)
                if (chars.find(str[p])==std::string::npos) break;
            str.erase (0, p);
        }
        if (dirs & STRTRIM_R) { // right trim
            int q, strlenm1=str.length()-1;
            for (q=0; q<max_count; ++q)
                if (chars.find(str[strlenm1-q])==std::string::npos) break;
            str.erase (str.length()-q, q);
        }        
        return (str);
    }
    inline 
    std::string strip_outer_quotes (std::string str, char* qq=NULL) {
        str = strtrim (str);
        
        std::string ret = strtrim (str, "\"");
        if (ret==str) {
            ret = strtrim (str, "'");
            if (qq && ret!=str) *qq = '\'';
        }
        else if (qq)
            *qq = '"';
        
        return (ret);
    }

    // ----------------

    inline 
    int is_bracket (char c, std::vector<char const*>& bracks, int indx=0) {
        for (size_t b=0; b<bracks.size(); ++b)
            if (c==bracks[b][indx]) 
                return (b);
        return (-1);
    }

    inline 
    std::vector<std::string> split_JSON_array (const std::string& str) { // TODO: Make efficient. This function is speed bottleneck.
        // splits, while respecting brackets and escapes
        std::vector<std::string> ret;
        
        std::string current;
        std::vector<int> bracket_stack;
        std::vector<int> quote_stack;
        bool escape_active = false;
        int bi;
        
        for (size_t a=0; a<str.length(); ++a) { // *
            
            // delimiter
            if ( bracket_stack.size()==0  &&  quote_stack.size()==0  &&  str[a]==JSONarraydelimiter ) {
                ret.push_back (current);
                current.clear(); bracket_stack.clear(); quote_stack.clear(); escape_active = false;
                continue; // to *
            }
            
            // ------------------------------------
            // checks for string
            
            if (quote_stack.size() > 0) { // already inside string
                if (str[a]==JSONcharescape)  // an escape character
                    escape_active = !escape_active;
                else if (!escape_active  &&  str[a]==JSONstringquotes[quote_stack.back()][1] ) { // close quote
                    quote_stack.pop_back();
                    escape_active = false;
                }
                else
                    escape_active = false;
                
                current.push_back (str[a]);
                continue; // to *
            }
            
            if (quote_stack.size()==0) { // check for start of string
                if ((bi = is_bracket (str[a], JSONstringquotes)) >= 0) {
                    quote_stack.push_back (bi);
                    current.push_back (str[a]);
                    continue; // to *
                }
            }
            
            // ------------------------------------
            // checks for comments
            
            if (quote_stack.size()==0) { // comment cannot start inside string
                
                // single-line commenst
                if (str.compare (a, JSONlinecommentstart.length(), JSONlinecommentstart) == 0) {
                    // ignore until end of line
                    size_t newline_pos = str.find ("\n", a);
                    if (newline_pos == std::string::npos)
                        newline_pos = str.find ("\r", a);
                    
                    if (newline_pos != std::string::npos)
                        a = newline_pos; // point to the newline character (a will be incremented)
                    else // the comment continues until EOF
                        a = str.length();
                    continue;
                }
            }
            
            // ------------------------------------
            // checks for brackets
            
            if ( bracket_stack.size()>0  &&  str[a]==JSONbrackets[bracket_stack.back()][1] ) { // check for closing bracket
                bracket_stack.pop_back();
                current.push_back (str[a]);
                continue;
            }
            
            if ((bi = is_bracket (str[a], JSONbrackets)) >= 0) {
                bracket_stack.push_back (bi);
                current.push_back (str[a]);
                continue; // to *
            }
            
            // ------------------------------------
            // otherwise
            current.push_back (str[a]);
        }
        
        if (current.length() > 0)
            ret.push_back (current);
        
        return (ret);
    }

    inline 
    std::string insert_tab_after_newlines (std::string str, bool pretty = true) {
        if (pretty == false) return (str);
        for (size_t a=0; a<str.length(); ++a)
            if (str[a]=='\n') {
                str.insert (a+1, JSONprinttab);
                a += JSONprinttab.length();
            }
        return (str);
    }


    // ============================================================

    // forward declarations
    class JSONparsedData;
    class JSON;

    // Objet and array typedefs
    typedef std::unordered_map <std::string,JSON>    JSONobject;
    typedef std::vector <JSON>                       JSONarray;

    // ------------------------------------
    // Main classes

    class JSON {
    /* Use: JSON("JSON_string_data").as<JSONobject>()["keyName"].as<JSONarray>()[2].as<int>()
            JSON("JSON_string_data")["keyName"][2].as<int>()  */
    private:
        // main data
        std::string data; // can be object, vector or leaf data
        bool _exists;      // whether the JSON resource exists.
        
        // parsed data
        JSONparsedData* parsed_data_p;
        
    public:
        // constructor
        JSON () : _exists (false), parsed_data_p (NULL) { } // no data field.
        
        JSON (std::string str) : data (str), _exists (true), parsed_data_p (NULL) { }
        JSON (const char* str) : JSON(std::string(str)) { }
        
        // other convertion
        template <class dataType>
        JSON (dataType d) : JSON(std::to_string(d)) { }
        
        // read from file and stream
        JSON (std::istream& is) : _exists (true), parsed_data_p (NULL) {
            data = std::string ( (std::istreambuf_iterator<char>(is)), (std::istreambuf_iterator<char>()) );
        }
        JSON (std::ifstream& ifs) : _exists (true), parsed_data_p (NULL) {
            std::istream& is = ifs;
            data = std::string ( (std::istreambuf_iterator<char>(is)), (std::istreambuf_iterator<char>()) );
        }
        
        // free allocated memory for parsed data
        ~JSON();
        
        // deep copy
        JSON (const JSON& r);
        JSON& operator= (const JSON& r);
        
        // ------------------------------------
        // parsers (old)
        JSONType parse (bool force=false);
        void parse_full (bool force=false, int max_depth=INT_MAX, int* parse_count_for_verbose_p=NULL); // recursively parse the entire JSON text
        // parser (new)
        void fast_parse (std::string* str_p=NULL, bool copy_string=false, int max_depth=INT_MAX, size_t* parse_start_str_pos=NULL); // TODO: finish.
        
        JSONobject& as_object (bool force=false);
        JSONarray& as_array (bool force=false);
        
        // ------------------------------------
        
        // access raw data and other attributes
        int size(void);
        std::string& raw_data (void) { return (data); }
        bool exists (void) { return (_exists); }
        bool is_parsed (void) { return (parsed_data_p!=NULL); }
        JSONType type (void);
        // emitter
        std::string as_str (bool print_comments=false, bool update_data=true, bool pretty=false);
        void print (bool print_comments=false, bool update_data=true, bool pretty=false) 
            { std::cout << as_str(print_comments,update_data,pretty) << std::endl; }
        
        // opertor[]
        JSON& operator[] (std::string key); // object
        JSON& operator[] (size_t indx); // array
        
        // ------------------------------------
        
        // as
        template <class dataType>
        dataType as (const dataType& def = dataType()) { // specialized outside class declaration
            if (!exists()) return (def);
            return dataType (data); // default behavior for unknown types: invoke 'dataType(std::string)'
        }
        
        // as_vector
        template <class dataType, class vectorType=std::vector<dataType> > // vectorType should have push_back method
        vectorType as_vector (const vectorType& def = vectorType());
        
        // as_map
        template <class dataType, class mapType=std::unordered_map<std::string,dataType> > // mapType should have operator[] defined
        mapType as_map (const mapType& def = mapType());    
    };

    // ------------------------------------------------------------

    class JSONparsedData {
    public:
        JSONobject object;
        JSONarray array;
        
        JSONType type;
        JSONparsedData() : type(JSON_UNKNOWN) {}
        
        // parser
        void parse (const std::string& data, JSONType typ = JSON_UNKNOWN) {
            std::string content = strtrim(data);
            
            if (typ==JSON_OBJECT || typ==JSON_UNKNOWN) {
                // parse as object:
                content = strtrim (strtrim (content, "{", 1, STRTRIM_L ), "}", 1, STRTRIM_R );
                if (content.length() != data.length()) { // a valid object
                    std::vector<std::string> nvPairs = split_JSON_array (content);
                    for (size_t a=0; a<nvPairs.size(); ++a) {
                        std::size_t assignmentPos = nvPairs[a].find (JSONobjectassignment);
                        object.insert (make_pair( 
                                            strip_outer_quotes (nvPairs[a].substr (0,assignmentPos) ) ,
                                            JSON (strtrim (nvPairs[a].substr (assignmentPos+1) ) )
                                   ) );
                    }
                    if (object.size() > 0) {
                        type = JSON_OBJECT;
                        return;
                    }
                }
            }
            
            if (typ==JSON_ARRAY || typ==JSON_UNKNOWN) {
                // parse as array
                content = strtrim (strtrim (content, "[", 1, STRTRIM_L ), "]", 1, STRTRIM_R );
                if (content.length() != data.length()) { // a valid array
                    std::vector<std::string> nvPairs = split_JSON_array (content);
                    for (size_t a=0; a<nvPairs.size(); ++a) 
                        array.push_back (JSON (strtrim (nvPairs[a]) ) );
                    if (array.size() > 0) {
                        type = JSON_ARRAY;
                        return;
                    }
                }
            }
            
            if (typ==JSON_UNKNOWN)
                type = JSON_LEAF;
        }
        
        
        // remove non-existing items inserted due to accessing
        int cleanup(void) {
        
            if (type==JSON_OBJECT) {
                bool found = true;
                while (found) {
                    found = false;
                    for (auto it=object.begin(); it!=object.end(); ++it)
                        if (!(it->second.exists())) {
                            object.erase(it);
                            found = true;
                            break; // break for loop since it is now invalid
                        }
                }
                return (object.size());
            }
            
            if (type==JSON_ARRAY) { // erases only the non-existent elements at the tail
                while (!(array[array.size()-1].exists()))
                    array.pop_back();
                return (array.size());
            }
            
            if (type==JSON_LEAF)
                return (1);
            
            return (0);
        }
        
        // size
        int size(void) { return (cleanup()); }
    };


    // ------------------------------------------------------------
    // JSON member functions
    inline 
    JSON::~JSON (){
        if (parsed_data_p) delete parsed_data_p;
    }
    inline 
    JSON::JSON (const JSON& r) {
        data=r.data;
        _exists = r._exists;
        if(r.parsed_data_p) parsed_data_p = new JSONparsedData(*(r.parsed_data_p));
        else parsed_data_p = NULL;
    }
    inline 
    JSON& JSON::operator= (const JSON& r) {
        data=r.data;
        _exists = r._exists;
        if(r.parsed_data_p) parsed_data_p = new JSONparsedData(*(r.parsed_data_p));
        else parsed_data_p = NULL;
        return *this;
    }
    inline 
    int JSON::size (void) {
        parse();
        return (parsed_data_p->size());
    }
    inline 
    JSONType JSON::type (void) {
        if (!exists()) return (JSON_UNINITIATED);
        parse(); // parse if not parsed
        return (parsed_data_p->type);
    }
    inline 
    std::string JSON::as_str (bool print_comments, bool update_data, bool pretty) {
        if (exists()) {
            std::string ret;
            parse(); // parse if not parsed
            parsed_data_p->cleanup();
            
            if (parsed_data_p->type==JSON_OBJECT) {
                ret = pretty ? "{\n" : "{";
                for (auto it=parsed_data_p->object.begin(); it!=parsed_data_p->object.end(); ++it) {
                    ret += (pretty ? JSONprinttab : "") + "\"" + it->first + "\":" + insert_tab_after_newlines( it->second.as_str (print_comments, update_data, pretty), pretty );
                    if (std::next(it) != parsed_data_p->object.end()) ret += ",";
                    if (print_comments && pretty == false)
                        ret += " // " + to_string(it->second.type());
                    if (pretty)
                        ret += "\n";
                }
                ret += "}";
            }
            else if (parsed_data_p->type==JSON_ARRAY) {
                ret = pretty ? "[\n" : "[";
                for (auto it=parsed_data_p->array.begin(); it!=parsed_data_p->array.end(); ++it) {
                    ret += (pretty ? JSONprinttab : "") + insert_tab_after_newlines( it->as_str (print_comments, update_data, pretty), pretty );
                    if (std::next(it) != parsed_data_p->array.end()) ret += ",";
                    if (print_comments && pretty == false)
                        ret += " // " + to_string(it->type());
                    if (pretty)
                        ret += "\n";
                }
                ret += "]";
            }
            else // JSON_LEAF or JSON_UNKNOWN
            {
                if(parsed_data_p->type==JSON_LEAF) {
                    if (data[0] != '\'' && data[0] != '"') {
                        if(!is_number(data) && !is_boolean(data) && !is_null(data)) {
                            data = "\""+data+"\"";
                        }
                    }
                    if (data[0] == '\'' && data[data.length() - 1] == '\'') {
                        data = data.substr(1,data.length() -2);
                        std::string tmp = "";
                        for(size_t i = 0; i < data.size(); ++i) {
                            if (data[i] == '"' && data[i-1] != '\\') {
                                tmp += "\\";
                            }
                            if (data[i] == '\'' && data[i-1] == '\\') {
                                tmp = tmp.substr(0, tmp.size()-1);
                            }
                            tmp += data[i];
                        }
                        data = "\""+tmp+"\"";
                    } else if (data[0] == '"' && data[data.length() - 1] == '"') {
                        data = data.substr(1,data.length() -2);
                        std::string tmp = "";
                        for(size_t i = 0; i < data.size(); ++i) {
                            if (data[i] == '"' && data[i-1] != '\\') {
                                tmp += "\\";
                            }
                            if (data[i] == '\'' && data[i-1] == '\\') {
                                tmp = tmp.substr(0, tmp.size()-1);
                            }
                            tmp += data[i];
                        }
                        data = "\""+tmp+"\"";
                    }
                }
                ret = strtrim (data);
            }
            
            if (update_data) data = ret;
            return (ret);
        }
        else
            return ("");
    }

    // Parsers
    inline 
    JSONType JSON::parse (bool force) {
        if (!parsed_data_p)  parsed_data_p = new JSONparsedData;
        if (parsed_data_p->type==JSON_UNKNOWN || force)  parsed_data_p->parse (data, JSON_UNKNOWN);
        return (parsed_data_p->type);
    }
    inline 
    void JSON::parse_full (bool force, int max_depth, int* parse_count_for_verbose_p) { // recursive parsing (slow)
        if (max_depth==0) return;
        if (!parsed_data_p)  parsed_data_p = new JSONparsedData;
        if (parsed_data_p->type==JSON_UNKNOWN || force)  parsed_data_p->parse (data, JSON_UNKNOWN);
        // verbose
        if (parse_count_for_verbose_p) {
            (*parse_count_for_verbose_p)++;
            if ( (*parse_count_for_verbose_p) % 100 == 0)
                std::cout << "parse_full: " << (*parse_count_for_verbose_p) << " calls." << std::endl;
        }
        // recursive parse children if not already parsed
        if (parsed_data_p->type==JSON_OBJECT) 
            for (auto it=parsed_data_p->object.begin(); it!=parsed_data_p->object.end(); ++it)
                it->second.parse_full (force, max_depth-1, parse_count_for_verbose_p);
        else if (parsed_data_p->type==JSON_ARRAY)
            for (auto it=parsed_data_p->array.begin(); it!=parsed_data_p->array.end(); ++it) 
                it->parse_full (force, max_depth-1, parse_count_for_verbose_p);
    }

    // ------------------------------------------------------------
    // ============================================================
    // FAST PARSER (Under construction. DO NOT use the following functions in your application.)
    inline 
    void JSON::fast_parse (std::string* str_p, bool copy_string, int max_depth, size_t* parse_start_str_pos) {
        // TODO: UNDER CONSTRUCTION...
        
        if (!str_p)
            str_p = &data;
        std::string& str = *str_p;
        
        // splits, while respecting brackets and escapes
        //std::vector<std::string> ret;
        
        //std::string current;
        std::vector<int> bracket_stack;
        std::vector<int> quote_stack;
        bool escape_active = false;
        int bi;
        
        bool initial_whitespaces = true;
        bool isroot = false;
        
        if (!parse_start_str_pos) {
            parse_start_str_pos = new size_t;
            *parse_start_str_pos = 0;
            isroot = true;
        }
        
        size_t a = *parse_start_str_pos;
        
        while (*parse_start_str_pos < str_p->length()) { // *
            
            // initial whitespace characters
            if (initial_whitespaces) {
                if (str[a] == ' ' || str[a] == '\n' || str[a] == '\r' || str[a] == '\t' ) {
                    ++a;
                    continue;
                }
                else {
                    if (str[a] == '{') // start of object
                        // ... TODO: seek_next ':'
                    
                    initial_whitespaces = false;
                }
            }
            
            
            // delimiter
            if ( bracket_stack.size()==0  &&  quote_stack.size()==0  &&  str[a]==JSONarraydelimiter ) {
                //ret.push_back (current);
                
                //current.clear();
                bracket_stack.clear(); quote_stack.clear(); escape_active = false;
                continue; // to *
            }
            
            // ------------------------------------
            // checks for string
            
            if (quote_stack.size() > 0) { // already inside string
                if (str[a]==JSONcharescape)  // an escape character
                    escape_active = !escape_active;
                else if (!escape_active  &&  str[a]==JSONstringquotes[quote_stack.back()][1] ) { // close quote
                    quote_stack.pop_back();
                    escape_active = false;
                }
                else
                    escape_active = false;
                
                //current.push_back (str[a]);
                continue; // to *
            }
            
            if (quote_stack.size()==0) { // check for start of string
                if ((bi = is_bracket (str[a], JSONstringquotes)) >= 0) {
                    quote_stack.push_back (bi);
                    //current.push_back (str[a]);
                    continue; // to *
                }
            }
            
            // ------------------------------------
            // checks for comments
            
            if (quote_stack.size()==0) { // comment cannot start inside string
                
                // single-line commenst
                if (str.compare (a, JSONlinecommentstart.length(), JSONlinecommentstart) == 0) {
                    // ignore until end of line
                    size_t newline_pos = str.find ("\n", a);
                    if (newline_pos == std::string::npos)
                        newline_pos = str.find ("\r", a);
                    
                    if (newline_pos != std::string::npos)
                        a = newline_pos; // point to the newline character (a will be incremented)
                    else // the comment continues until EOF
                        a = str.length();
                    continue;
                }
            }
            
            // ------------------------------------
            // checks for brackets
            
            if ( bracket_stack.size()>0  &&  str[a]==JSONbrackets[bracket_stack.back()][1] ) { // check for closing bracket
                bracket_stack.pop_back();
                //current.push_back (str[a]);
                continue;
            }
            
            if ((bi = is_bracket (str[a], JSONbrackets)) >= 0) {
                bracket_stack.push_back (bi);
                //current.push_back (str[a]);
                continue; // to *
            }
            
            // ------------------------------------
            // otherwise
            //current.push_back (str[a]);
        }
        
        /*if (current.length() > 0)
            ret.push_back (current); */
        
        if (isroot)
            delete parse_start_str_pos;
        
        // return (ret);
    }

    // ============================================================

    // ------------------------------------------------------------
    inline 
    JSONobject& JSON::as_object (bool force) {
        if (!parsed_data_p)  parsed_data_p = new JSONparsedData;
        if (parsed_data_p->type==JSON_UNKNOWN || force)  parsed_data_p->parse (data, JSON_OBJECT);
        return (parsed_data_p->object);
    }
    inline 
    JSON& JSON::operator[] (std::string key) { // returns reference
        return ( (as_object())[key] ); // will return empty resource (with _exists==false) if 
                                                // either this resource does not exist, is not an object, or the key does not exist
    }
    inline 
    JSONarray& JSON::as_array (bool force) {
        if (!parsed_data_p)  parsed_data_p = new JSONparsedData;
        if (parsed_data_p->type==JSON_UNKNOWN || force)  parsed_data_p->parse (data, JSON_ARRAY);
        return (parsed_data_p->array);
    }
    inline 
    JSON& JSON::operator[] (size_t indx) { // returns reference
        as_array();
        if (indx >= parsed_data_p->array.size())
            parsed_data_p->array.resize(indx+1); // insert empty resources
        return (parsed_data_p->array[indx]); // will return empty resource (with _exists==false) if 
                                                // either this resource does not exist, is not an object, or the key does not exist
    }

    // ------------------------------------------------------------
    // special 'as':

    template <class dataType, class vectorType> inline 
    vectorType JSON::as_vector (const vectorType& def) { // returns copy -- for being consistent with other 'as' specializations
        if (!exists()) return (def);
        vectorType ret;
        as_array();
        for (auto it=parsed_data_p->array.begin(); it!=parsed_data_p->array.end(); ++it)
            ret.push_back (it->as<dataType>());
        return (ret);
    }

    template <class dataType, class mapType> inline 
    mapType JSON::as_map (const mapType& def) { // returns copy -- for being consistent with other 'as' specializations
        if (!exists()) return (def);
        mapType ret;
        as_object();
        for (auto it=parsed_data_p->object.begin(); it!=parsed_data_p->object.end(); ++it)
            ret[it->first] = it->second.as<dataType>();
        return (ret);
    }

    // ============================================================
    // Specialized .as() member functions

    // Helper preprocessor directives
    #define rsjObject  as<JSONobject>()
    #define rsjArray   as<JSONarray>()
    #define rsjAs(t)   as<t>()
    // JSONobject
    template <> inline 
    JSONobject JSON::as<JSONobject> (const JSONobject& def) { // returns copy -- for being consistent with other 'as' specializations
        if (!exists()) return (def);
        return (as_object());
    }
    // JSONarray
    template <> inline 
    JSONarray  JSON::as<JSONarray> (const JSONarray& def) { // returns copy -- for being consistent with other 'as' specializations
        if (!exists()) return (def);
        return (as_array());
    }
    // ------------------------------------
    // Elementary types
    // String
    template <> inline 
    std::string  JSON::as<std::string> (const std::string& def) {
        if (!exists()) return (def);
        char qq = '\0';
        std::string ret = strip_outer_quotes (data, &qq);
        std::vector< std::vector<std::string> > escapes = { {"\\n","\n"}, {"\\r","\r"}, {"\\t","\t"}, {"\\\\","\\"} };
        if (qq=='"') {
            escapes.push_back ({"\\\"","\""});
        } else if (qq=='\'') {
            escapes.push_back ({"\\'","'"});
        }
        for (size_t a=0; a<escapes.size(); ++a) 
            for ( std::size_t start_pos=ret.find(escapes[a][0]); start_pos!=std::string::npos; start_pos=ret.find(escapes[a][0],start_pos) ) {
                ret.replace (start_pos, escapes[a][0].length(), escapes[a][1]);
                start_pos += escapes[a][1].length();
            }
        return (ret);
    }
    // integer
    template <> inline 
    int  JSON::as<int> (const int& def) {
        if (!exists()) return (def);
        return (atoi (strip_outer_quotes(data).c_str() ) );
    }
    // double
    template <> inline 
    double  JSON::as<double> (const double& def) {
        if (!exists()) return (def);
        return (atof (strip_outer_quotes(data).c_str() ) );
    }
    // bool
    template <> inline 
    bool  JSON::as<bool> (const bool& def) {
        if (!exists()) return (def);
        std::string cleanData = strip_outer_quotes (data);
        if (cleanData == "true" || cleanData == "TRUE" || cleanData == "True" || atoi(cleanData.c_str()) != 0) return (true);
        return (false);
    }
    // ------------------------------------
    // Other types
} // jsonlib
#endif
