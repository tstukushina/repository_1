from airflow import DAG
from airflow.operators import PythonOperator
from datetime import datetime

default_args = {
    'owner': 't.stukushina',
    'depends_on_past': False,
    'start_date': datetime(2020, 12, 2),
    'retries': 0
}

dag = DAG('mini_project',
          default_args = default_args,
          schedule_interval = '00 12 * * 1')

def create_report():
    import pandas as pd
  
    #  Считываем файл 
    path_to_data = 'https://docs.google.com/spreadsheets/d/e/2PACX-1vR-ti6Su94955DZ4Tky8EbwifpgZf_dTjpBdiVH0Ukhsq94jZdqoHuUytZsFZKfwpXEUCKRFteJRc9P/pub?gid=889004448&single=true&output=csv'
    df = pd.read_csv(path_to_data)

    #  Создаем сводную таблицу с количество показов и кликов
    res = df.groupby(['date','event'], as_index = False)\
            .agg({'ad_id': 'count'})\
            .rename(columns = {'ad_id': 'count_event'})\
            .pivot(index = 'date', columns = 'event', values = 'count_event')\
            .reset_index()

    #  Добавляем CTR = c/v
    res['CTR'] = res['click']/res['view']

    #  Добавляем суммарные затраты 
    res['spent_money'] = df.query('event == "view"')\
                           .groupby('date',as_index = False)\
                           .agg({'ad_cost': 'sum'}).ad_cost / 1000 

    #  Расчитываем насколько изменились показатели (%)
    res = res.rename(index = res.date).drop(res.columns[0], axis=1)
    res = res.T
    res['delta_%'] = (res['2019-04-02'] - res['2019-04-01'])/res['2019-04-01']*100

    #  Готовим данные за 2019-04-02 к записи в файл
    cl = int(res.at['click', '2019-04-02']) # количесво кликов
    cld = round(res.at['click','delta_%']) # изменение кликов

    v = int(res.at['view', '2019-04-02']) # количесво показов
    vd = round(res.at['view','delta_%']) # изменение показов

    ct = round(res.at['CTR', '2019-04-02'],3)  # CTR
    ctd = round(res.at['CTR','delta_%']) # изменение CTR

    m = round(res.at['spent_money', '2019-04-02']) # затраты
    md = round(res.at['spent_money','delta_%']) # изменение затрат

    #  Создаем отчет 
    report = (f'''Отчет по объявлению 121288 за 2 апреля 
Траты: {m} рублей ({md}%)  
Показы: {v} ({vd}%) 
Клики: {cl} ({cld}%) 
CTR: {ct} ({ctd}%) ''')
    
    print('Report is created')
    # Запишем отчет в  текстовый файл
    with open('mini_project_report.txt',"w") as f:
            f.write(report)
            f.close()
           
    print('Report is written')
    
def send_report():
    import requests
    from urllib.parse import urlencode       
    token = '1353796803:AAH_h364znxyQxFVUOb-UMrTcnyUp8vbeW4'
    chat_id = 1047700180  # your chat id

    #  Отправляем сообщение об отчете:
    message = 'Отчет за 2020-04-02:'
    params = {'chat_id': chat_id, 'text': message}
    base_url = f'https://api.telegram.org/bot{token}/'
    url = base_url + 'sendMessage?' + urlencode(params)
    resp = requests.get(url)

    #  Отправляем файл с отчетом:
    filepath = 'mini_project_report.txt'
    url = base_url + 'sendDocument?' + urlencode(params)
    files = {'document': open(filepath, 'rb')}
    resp = requests.get(url, files=files)
    
# Описываем таски   
t1 = PythonOperator(
    task_id = 'task_1',
    python_callable = create_report(),
    dag=dag)

t2 = PythonOperator(
    task_id = 'task_2',
    python_callable = send_report(),
    dag=dag)


t1 >> t2
