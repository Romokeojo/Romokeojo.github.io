# -*- coding: utf-8 -*-'
"""
Created on Wed Nov  8 14:04:42 2023

@author: s384308
"""

import requests
import datetime
import time

"""Checking the key"""


def check_key(key):
    url = 'https://api.purpleair.com/v1/keys'
    headers = {'X-API-Key':key}
    response = requests.get(url, headers=headers)
    response_code = response.status_code
    if response_code ==200:
        print('success{}'.format(response.text))
    else:
        print('error{}'.format(response.text))
    return
        
#check_key('0DCD1405-6E0A-11EE-A8AF-42010A80000A')

"""Getting data now

For more info: https://realpython.com/python-requests/#query-string-parameters"""

"""def sensor_data(key, field):
    url = 'https://api.purpleair.com/v1/sensors/99419'
    headers = {'X-API-Key':key}
    payload = {'fields':'temperature,pm2.5,pm10.0'}
    response = requests.get(url, headers=headers, params=payload) 
    response_code = response.status_code
    if response_code ==200:
        print('success{}'.format(response.text))
    else:
        print('error{}'.format(response.text))
    return

sensor_data('0DCD1405-6E0A-11EE-A8AF-42010A80000A', 58)"""

    
    
def unixtime_convert(date_start):
    date_obj = datetime.datetime.strptime(date_start, '%Y/%m/%d')
    unixtime_start = time.mktime(date_obj.timetuple())
    
    return unixtime_start

def data_per_date(data_fields,start, end, key, sensor_index):
    start_u = unixtime_convert(start)
    end_u = unixtime_convert(end)
    
    url = 'https://api.purpleair.com/v1/sensors/{}/history'.format(sensor_index)

    headers = {'X-API-Key':key}
    
    payload = {
        'fields':data_fields,
        'start_timestamp': start_u,
        'end_timestamp':end_u,'average':1440}
    response = requests.get(url, headers=headers, params=payload) 
    response_code = response.status_code
    retvar = ''
    if response_code ==200:
        print('success')
        retvar = response.json()
    else:
        print('error{}'.format(response.json()))
    
    return retvar

"""Getting data for all sensors"""
"""
sensor_index=[99389,98945,61087,61393,99469,99417,99387]
for i in sensor_index:"""
    
var = data_per_date('temperature,pm2.5_atm,pm10.0_atm','2022/06/01', '2022/08/31', 
              '0DCD1405-6E0A-11EE-A8AF-42010A80000A', '99389')
'''print(var)

def average(x, y):
    avg_one = (x+y)/2
    return avg_one'''



