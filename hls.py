import sys

if __name__ == '__main__':
  if len(sys.argv) < 2:
    sys.exit()

  text = ''
  with open(sys.argv[1],'r') as fp:
    text = fp.read()

  fw = open('hls.m3u8','w')
  fs = open('stream.sh','w')
  lines = text.split('\n')
  i = 1
  for line in lines:
    if 'https://' in line:
      name = 'seg-%d' % i
      print("wget --inet4-only '%s' -O '%s'" % (line, name))
      fw.write("%s\n" % name)
      fs.write("dd if=%s of=%s.ts bs=1 skip=8\n" % (name, name))
      i += 1
    else:
      fw.write("%s\n" % line)
  fw.close()
  fs.close()
