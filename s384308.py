# -*- coding: utf-8 -*-
"""
Created on Wed Nov  8 20:16:56 2023

@author: omodo
"""

import requests
from datetime import datetime
    
def stac_data(a, b, c):
    """return stac Api catalog data.
    
    keywords arguments:
    a(string): the start date
    b(string): the end date
    c(array): bounding box
    
    returns:
    stac catalog datasets for the stipulated period of time
    """
    # to convert to datetime period in RFC3339 format
    date_object_start = datetime.strptime(a, '%Y/%m/%d')     
    date_object_end = datetime.strptime(b, '%Y/%m/%d')
    date1 = date_object_start.strftime('%Y-%m-%dT%H:%M:%SZ')
    date2 = date_object_end.strftime('%Y-%m-%dT%H:%M:%SZ')
    period = f'{date1}/{date2}'
   
    headers = { 'Accept': 'application/geo+json'}
    url = 'https://earth-search.aws.element84.com/v1/search'
    parameter = {'bbox': c,  'limit': 10000,
    'datetime': period, 'collections': [
    'sentinel-2-l2a', 'landsat-c2-l2'], 
     'fields': {'include': ['properties', 'id'], 
    'exclude': ['bbox', 'geometry', 
   'assets', 'stac_version', 'stac_extensions', 'type']}}    
    response = requests.post(url, 
    json=parameter, 
    headers = headers)
    response_code = response.status_code
    retvar = ''
    if response_code ==200:
        print('success')
        retvar = response.json()
    else:
        print('error{}'.format(response.json()))
    return retvar






    













