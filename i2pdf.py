# -*- coding: utf-8 -*-

from PIL import Image

if __name__ == "__main__":
    import sys, os
    if len(sys.argv[1:]) == 0:
        print("Usage: {} <image>".format(sys.argv[0]))
        sys.exit(1)

    infile = sys.argv[1]
    outfile = os.path.splitext(infile)[0] + ".pdf"

    if infile != outfile:
        try:
            img = Image.open(infile)
            pdf = img.convert('RGB')

            pdf.save(outfile)
        except:
            e = sys.exc_info()[0]
            print("Error !", e)

    sys.exit(0)
