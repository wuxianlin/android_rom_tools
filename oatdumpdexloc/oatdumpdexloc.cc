/*
 * Copyright (C) 2017 wuxianlin(wuxianlinwxl@gmail.com)
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <unistd.h>

#define OAT_MAGIC "oat\n"
#define OAT_MAGIC_SIZE 4

int usage() {
    printf("usage: oatlocation\n");
    printf("\t-i|--input oatfile\n");
    return 0;
}

int main(int argc, char** argv)
{
    char* filename = NULL;
    argc--;
    argv++;
    while(argc > 0){
        char *arg = argv[0];
        char *val = argv[1];
        argc -= 2;
        argv += 2;
        if(!strcmp(arg, "--input") || !strcmp(arg, "-i")) {
            filename = val;
        } else {
            return usage();
        }
    }
    
    if (filename == NULL) {
        return usage();
    }
    FILE* file = fopen(filename, "rb");
    if (file == NULL)
    {
        printf("file exist?\n");
        return 0;
    }
    fseek(file, 0x1000, SEEK_SET);
    char magic[OAT_MAGIC_SIZE];
    fread(&magic, sizeof(char), OAT_MAGIC_SIZE, file);
    if (memcmp(magic, OAT_MAGIC, OAT_MAGIC_SIZE)!=0)
    {
        printf("oat file?\n");
        return 0;
    }
    char version[4];
    int ver = 0;
    fread(&version, sizeof(char), 4, file);
    for (int i=0;i<3;i++)
    {
	ver = ver*10 + version[i] - '0';
    }
    //printf("oat version:%d\n", ver);
    if (ver < 127)
    {
        fseek(file, 0xc, SEEK_CUR);
        uint32_t dex_file_count;
        fread(&dex_file_count, sizeof(uint32_t), 1, file);
        fseek(file, 0x2c, SEEK_CUR);
        uint32_t path_length;
        fread(&path_length, sizeof(uint32_t), 1, file);
        fseek(file, path_length, SEEK_CUR);
        uint32_t location_length;
        for (int i = 0; i < dex_file_count; i++)
        {
            fread(&location_length, sizeof(uint32_t), 1, file);
            char *location = (char *)malloc(location_length+1);
            memset(location, 0, location_length+1);
            fread(location, sizeof(char), location_length, file);
            printf("%s\n", location);
            free(location);
            fseek(file, 0x10, SEEK_CUR);
        }
    } else {
        fseek(file, 0xc, SEEK_CUR);
        uint32_t dex_file_count;
        fread(&dex_file_count, sizeof(uint32_t), 1, file);
        //printf("dex_file_count:%d\n", dex_file_count);
        uint32_t oat_dex_files_offset;
        fread(&oat_dex_files_offset, sizeof(uint32_t), 1, file);
        fseek(file, 0x1000+oat_dex_files_offset, SEEK_SET);
        uint32_t location_length;
        for (int i = 0; i < dex_file_count; i++)
        {
            fread(&location_length, sizeof(uint32_t), 1, file);
            char *location = (char *)malloc(location_length+1);
            memset(location, 0, location_length+1);
            fread(location, sizeof(char), location_length, file);
            printf("%s\n", location);
            free(location);
            fseek(file, ver<132?0x18:0x20, SEEK_CUR);
        }
    }
}
