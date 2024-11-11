#!/usr/bin/env python
# coding: utf-8

# In[2]:


import sensornew2
import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
import datetime
import time


# In[3]:


data = sensornew2.data_per_date(
    'temperature,pm2.5_atm,pm10.0_atm',
    '2022/06/01',
    '2022/08/31',
    '0DCD1405-6E0A-11EE-A8AF-42010A80000A',
    '99389'
)


# In[4]:


cols = ['time_stamp', 'temperature', 'pm2.5_atm', 'pm10.0_atm']

df = pd.DataFrame(data['data'])
df.columns = cols


# In[5]:


df


# In[6]:


df['sensor_id'] = 99389


# In[7]:


df;


# In[11]:


data = sensornew2.data_per_date(
    'temperature,pm2.5_atm,pm10.0_atm',
    '2022/06/01',
    '2022/08/31',
    '0DCD1405-6E0A-11EE-A8AF-42010A80000A',
    '98945'
)


# In[12]:


cols = ['time_stamp', 'temperature', 'pm2.5_atm', 'pm10.0_atm']

df_two = pd.DataFrame(data['data'])
df_two.columns = cols


# In[13]:


df_two['sensor_id'] = 98945


# In[14]:


df_two;


# In[15]:


data = sensornew2.data_per_date(
    'temperature,pm2.5_atm,pm10.0_atm',
    '2022/06/01',
    '2022/08/31',
    '0DCD1405-6E0A-11EE-A8AF-42010A80000A',
    '61087'
)


# In[16]:


cols = ['time_stamp', 'temperature', 'pm2.5_atm', 'pm10.0_atm']

df_three = pd.DataFrame(data['data'])
df_three.columns = cols


# In[17]:


df_three['sensor_id'] = 61087


# In[18]:


df_three;


# In[19]:


data = sensornew2.data_per_date(
    'temperature,pm2.5_atm,pm10.0_atm',
    '2022/06/01',
    '2022/08/31',
    '0DCD1405-6E0A-11EE-A8AF-42010A80000A',
    '61393'
)


# In[20]:


cols = ['time_stamp', 'temperature', 'pm2.5_atm', 'pm10.0_atm']

df_four = pd.DataFrame(data['data'])
df_four.columns = cols


# In[21]:


df_four['sensor_id'] = 61393


# In[22]:


df_four;


# In[23]:


data = sensornew2.data_per_date(
    'temperature,pm2.5_atm,pm10.0_atm',
    '2022/06/01',
    '2022/08/31',
    '0DCD1405-6E0A-11EE-A8AF-42010A80000A',
    '99469'
)


# In[24]:


cols = ['time_stamp', 'temperature', 'pm2.5_atm', 'pm10.0_atm']

df_five = pd.DataFrame(data['data'])
df_five.columns = cols


# In[25]:


df_five['sensor_id'] = 99469


# In[26]:


df_five;


# In[27]:


data = sensornew2.data_per_date(
    'temperature,pm2.5_atm,pm10.0_atm',
    '2022/06/01',
    '2022/08/31',
    '0DCD1405-6E0A-11EE-A8AF-42010A80000A',
    '99417'
)


# In[28]:


cols = ['time_stamp', 'temperature', 'pm2.5_atm', 'pm10.0_atm']

df_six = pd.DataFrame(data['data'])
df_six.columns = cols


# In[29]:


df_six['sensor_id'] = 99417


# In[30]:


df_six;


# In[31]:


data = sensornew2.data_per_date(
    'temperature,pm2.5_atm,pm10.0_atm',
    '2022/06/01',
    '2022/08/31',
    '0DCD1405-6E0A-11EE-A8AF-42010A80000A',
    '99387'
)


# In[32]:


cols = ['time_stamp', 'temperature', 'pm2.5_atm', 'pm10.0_atm']

df_seven = pd.DataFrame(data['data'])
df_seven.columns = cols


# In[33]:


df_seven['sensor_id'] = 99387


# In[34]:


df_seven;


# In[35]:


concatenated = pd.concat([df, df_two, df_three, df_four, df_five, df_six, df_seven], axis="rows")


# In[36]:


concatenated


# In[37]:


concatenated.groupby(['time_stamp']).mean();


# In[41]:


final = concatenated.groupby(['time_stamp']).mean().reset_index()


# In[124]:


final


# In[139]:


x = final['pm2.5_atm'] 
x_sec = final['pm10.0_atm'] 
y = final['temperature']        # Sample data.
fig = plt.figure()
ax = fig.gca()
ax.plot(figuresize=(5, 5), layout='constrained')
_ = ax.vlines(x=15, ymin=54, ymax=94, colors='k')
ax.plot(figuresize=(5, 5), layout='constrained')
_ = ax.vlines(x=45, ymin=54, ymax=94, colors='k')
ax.scatter(x, y, label='pm2.5_atm') 
# Plot some data on the (implicit) axes. 
ax.scatter(x_sec, y, label='pm10.0_atm') # etc. 
ax.set_xlabel('particulate_matter') 
ax.set_ylabel('temperature') 
ax.set_title("Extreme weather") 
ax.legend()
fig.savefig('final2.png')


# In[106]:


basedata = pd.read_csv('AQ_1161100_2022-06-01_2022-08-31.csv');



# In[113]:


basedata;


# In[129]:


final['time_stamp']= pd.to_datetime(final['time_stamp'], unit='s', origin='unix')


# In[128]:


final_two


# In[130]:


final


# In[134]:


#x = final['pm2.5_atm'] 
x_sec = final['pm10.0_atm'] 
y = final['time_stamp']        # Sample data.
fig = plt.figure()
ax = fig.gca()
ax.plot(figuresize=(5, 5), layout='constrained')
_ = ax.vlines(x=15, ymin=2022-5-31, ymax=2022-8-31, colors='k')
ax.scatter(x, y, label='pm2.5_atm') 
# Plot some data on the (implicit) axes. 
ax.scatter(x_sec, y, label='pm10.0_atm') # etc. 
ax.set_xlabel('pms') 
ax.set_ylabel('temperature') 
ax.set_title("Extreme weather") 
ax.legend();


# In[ ]:


plt.savefig('foo.png')
plt.savefig('foo.pdf')

