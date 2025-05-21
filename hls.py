import sys

if __name__ == '__main__':
  if len(sys.argv) < 2:
    sys.exit()

  text = ''
  with open(sys.argv[1],'r') as fp:
    text = fp.read()

  fw = open('hls.m3u8','w')
  fs = open('stream.sh','w')
  ft = open('list.txt','w')
  lines = text.split('\n')
  i = 1
  for line in lines:
    if 'https://' in line:
      name = 'seg-%d' % i
      print("echo 'Download %s ...'\nwget -q --inet4-only '%s' -O '%s'" % (name, line, name))
      fw.write("%s.ts\n" % name)
      fs.write("echo 'build %s.ts'\ndd if=%s of=%s.ts bs=1 skip=8\nrm -rf '%s'\n" % (name, name, name, name))
      ft.write("file '%s.ts'\n" % name)
      i += 1
    else:
      fw.write("%s\n" % line)
  fw.close()
  fs.close()
  ft.close()

print('ffmpeg -f concat -safe 0 -i list.txt -c copy output.mp4')
