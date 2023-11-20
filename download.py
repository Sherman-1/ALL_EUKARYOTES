import pandas as pd
import time
data = pd.DataFrame()

for group in ["fungi","invertebrate","plant","protozoa","vertebrate_mammalian","vertebrate_other"]:
    
    url = "https://ftp.ncbi.nlm.nih.gov/genomes/refseq/"+group+"/assembly_summary.txt"
    tmp = pd.read_csv(url, sep="\t", skiprows=1)
    data = pd.concat([data,tmp])
    # Don't get kicked out by NCBI
    time.sleep(2)



ftps = data.ftp_path.to_list()

# Turn ftps into list of tuples with assembly accession and ftp path

urls = [ftp+"/"+ftp.split("/")[-1]+"_translated_cds.faa.gz" for ftp in ftps]


# Based on URLs, download the files in the "./CDS/" folder and unzip them in the same folder at the same time

import os
import urllib.request
import gzip
import shutil
import time

i = 0

for url in urls:
    try:
        print(url)
        file_name = url.split("/")[-1]
        print(file_name)
        urllib.request.urlretrieve(url, "./CDS/"+file_name)
        with gzip.open("./CDS/"+file_name, 'rb') as f_in:
            with open("./CDS/"+file_name[:-3], 'wb') as f_out:
                shutil.copyfileobj(f_in, f_out)
        os.remove("./CDS/"+file_name)
        time.sleep(2)
        i += 1
        if i > 5:
            break
    except:
        print("Error with "+url)
        pass

