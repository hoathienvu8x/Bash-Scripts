# -*- coding: utf-8 -*-
import regex as re
import string

def isPunct(s):
    for c in string.punctuation:
        if c in s:
            return True
    return False

text = u'Ông Nguyễn Khắc Chúc  đang làm việc tại Đại học Quốc gia Hà Nội. Bà Lan, vợ ông Chúc, cũng làm việc tại đây.'

tmp = re.split(r'\s+',text)
Regex = {
    "ELLIPSIS":"\\.{2,}",
    "EMAIL":"([\\w\\d_\\.-]+)@(([\\d\\w-]+)\\.)*([\\d\\w-]+)",
    "FULL_DATE":"(0?[1-9]|[12][0-9]|3[01])(\\/|-|\\.)(1[0-2]|(0?[1-9]))((\\/|-|\\.)\\d{4})",
    "MONTH":"(1[0-2]|(0?[1-9]))(\\/)\\d{4}",
    "DATE":"(0?[1-9]|[12][0-9]|3[01])(\\/)(1[0-2]|(0?[1-9]))",
    "TIME":"(\\d\\d:\\d\\d:\\d\\d)|((0?\\d|1\\d|2[0-3])(:|h)(0?\\d|[1-5]\\d)(’|'|p|ph)?)",
    "MONEY":"\\p{Sc}\\d+([\\.,]\\d+)*|\\d+([\\.,]\\d+)*\\p{Sc}",
    "PHONE_NUMBER":"(\\(?\\+\\d{1,2}\\)?[\\s\\.-]?)?\\d{2,}[\\s\\.-]?\\d{3,}[\\s\\.-]?\\d{3,}",
    "URL":"(((https?|ftp):\\/\\/|www\\.)[^\\s/$.?#].[^\\s]*)|(https?:\\/\\/)?(www\\.)?[-a-zA-Z0-9@:%._\\+~#=]{2,256}\\.[a-z]{2,6}\\b([-a-zA-Z0-9@:%_\\+.~#?&//=]*)",
    "NUMBER":"[-+]?\\d+([\\.,]\\d+)*%?\\p{Sc}?",
    "PUNCTUATION":",|\\.|:|\\?|!|;|-|_|\"|'|“|”|\\||\\(|\\)|\\[|\\]|\\{|\\}|âŸ¨|âŸ©|Â«|Â»|\\\\|\\/|\\â€˜|\\â€™|\\â€œ|\\â€�|â€¦|…|‘|’|·",
    "SPECIAL_CHAR":"\\~|\\@|\\#|\\^|\\&|\\*|\\+|\\-|\\â€“|<|>|\\|",
    "EOS_PUNCTUATION":"(\\.+|\\?|!|…)",
    "SHORT_NAME":"([\\p{L}]+([\\.\\-][\\p{L}]+)+)|([\\p{L}]+-\\d+)",
    "WORD_WITH_HYPHEN":"\\p{L}+-\\p{L}+(-\\p{L}+)*",
    "ALLCAP":"[A-Z]+\\.[A-Z]+"
}
Regex["NUMBERS_EXPRESSION"] = Regex["NUMBER"] + "([\\+\\-\\*\\/]" + Regex["NUMBER"] + ")*"
VN_abbreviation = ["M.City", "V.I.P", "PGS.Ts", "MRS.", "Mrs.", "Man.United", "Mr.", "SHB.ĐN", "Gs.Bs", "U.S.A", "TMN.CSG", "Kts.Ts", "R.Madrid", "Tp.", "T.Ư", "D.C", "Gs.Tskh", "PGS.KTS", "GS.BS", "KTS.TS", "PGS-TS", "Co.", "S.H.E", "Ths.Bs", "T&T.HN", "MR.", "Ms.", "T.T.P", "TT.", "TP.", "ĐH.QGHN", "Gs.Kts", "Man.Utd", "GD-ĐT", "T.W", "Corp.", "ĐT.LA", "Dr.", "T&T", "HN.ACB", "GS.KTS", "MS.", "Prof.", "GS.TS", "PGs.Ts", "PGS.BS", "﻿BT.", "Ltd.", "ThS.BS", "Gs.Ts", "SL.NA", "Th.S", "Gs.Vs", "PGs.Bs", "T.O.P", "PGS.TS", "HN.T&T", "SG.XT", "O.T.C", "TS.BS", "Yahoo!", "Man.City", "MISS.", "HA.GL", "GS.Ts", "TBT.", "GS.VS", "GS.TSKH", "Ts.Bs", "M.U", "Gs.TSKH", "U.S", "Miss.", "GD.ĐT", "PGs.Kts", "St.", "Ng.", "Inc.", "Th.", "N.O.V.A"]
VN_exception = ["Wi-fi", "17+", "km/h", "M7", "M8", "21+", "G3", "M9", "G4", "km3", "m/s", "km2", "5g", "4G", "8K", "3g", "E9", "U21", "4K", "U23", "Z1", "Z2", "Z3", "Z4", "Z5", "Jong-un", "u19", "5s", "wi-fi", "18+", "Wi-Fi", "m2", "16+", "m3", "V-League", "Geun-hye", "5G", "4g", "Z3+", "3G", "km/s", "6+", "u21", "WI-FI", "u23", "U19", "6s", "4s"]
def isAny(s,l):
    for v in l:
        if v in s:
            return True
    return False

words = []
for word in tmp:
    word = word.strip()
    if len(word) == 1 or not isPunct(word):
        words.append(word)
        continue

    if word[-1:] == ',':
        words.append(word[:-1])
        words.append(',')
        continue

    if isAny(word, VN_abbreviation):
        words.append(word)
        continue

    if word[-1:] == '.' and word[-2:-1].isalpha():
        if (len(word) == 2 and word[-2:-1].isupper()) or re.compile(Regex["SHORT_NAME"]).search(word):
            words.append(word)
            continue
        words.append(word[:-1])
        words.append('.')
        continue

    if isAny(word, VN_exception):
        words.append(word)
        continue

    abb = False
    for e in VN_abbreviation:
        i = word.find(e)
        if i < 0:
            continue
        abb = True
        words.append(word[:i])
        words.append(word[i:i+len(e)])
        if i + len(e) < len(word):
            words.append(word[i+len(e):])
        break
    if abb:
        continue
    Exp = False
    for e in VN_exception:
        i = word.find(e)
        if i < 0:
            continue
        Exp = True
        words.append(word[:i])
        words.append(word[i:i+len(e)])
        if i + len(e) < len(word):
            words.append(word[i+len(e):])
        break
    if Exp:
        continue

    matching = False
    for reg in Regex:
        if re.compile(Regex[reg]).search(word):
            words.append(word)
            matching = True
            break

    if matching:
        continue

    for reg in Regex:
        m = re.compile(Regex[reg]).search(word)
        if m:
            if reg == "URL":
                eles = re.split(r'\.',word)
                hasURL = True
                for el in eles:
                    if len(el) == 1 and el[0].isupper():
                        hasURL = False
                        break
                    for j in range(len(el)):
                        if el[j] >= 128:
                            hasURL = False
                            break
                if hasURL:
                    i, e = m.span()
                    words.append(word[:i])
                    words.append(word[i:e])
                    if e < len(word):
                        words.append(word[e:])
                else:
                    continue
            elif reg == "MONTH":
                i, e = m.span()
                hasLetter = False
                for j in range(i):
                    if word[j].isalpha():
                        words.append(word[:i])
                        words.append(word[i:e])
                        if e < len(word):
                            words.append(word[e:])
                        hasLetter = True
                        break
                if not hasLetter:
                    words.append(word)
            else:
                i, e = m.span()
                words.append(word[:i])
                words.append(word[i:e])
                if e < len(word):
                    words.append(word[e:])
            matching = True
            break

    if not matching:
        words.append(word)

words = [ word for word in words if word.strip() ]

sentences = re.split(r'\.\s+',re.sub(r'\s{2,}',' ',text))

print('Words', words)
print('Sentences',sentences)


tokens = []
for word in words:
    word = word.strip()
    if not word:
        continue
    if word == ',' or word == '.':
        if len(tokens) > 0:
            tokens[len(tokens)-1] = tokens[len(tokens)-1] + word
            continue
        tokens.append(word)
        continue
    tokens.append(word)

print("Join", " ".join(tokens))
