#!/usr/bin/env python3

import os
import sys
import zstandard


class ZstdImageExtract:
    def __init__(self, f, o):
        self.decoder = zstandard.ZstdDecompressor()
        self.file = f
        self.output = o
        self.BUFSIZE = 8192
        self.ALIGN = 0x2000000

    def extract(self, cover=False):
        file_size = os.path.getsize(self.file)
        if file_size < self.ALIGN:
            cnt = 1
        else:
            cnt = file_size // self.ALIGN + 1
        with open(self.file, 'rb') as f, open(self.output, 'wb') as f2:
            for i in range(cnt):
                f.seek(i * self.ALIGN)
                dec = self.decoder.decompressobj()
                while not dec.eof:
                    f2.write(dec.decompress(f.read(self.BUFSIZE)))
                f2.write(dec.flush())
        if cover:
            os.remove(self.file)
            os.rename(self.output, self.file)

if __name__ == '__main__':
    ZstdImageExtract(sys.argv[1], sys.argv[2]).extract(cover=True)
