#!/bin/bash

# paths
app='/srv/app'
manage=$app'/manage.py'
wsgi=$app'/wsgi.py'
static='/srv/static/'
media='/srv/media/'
src='/srv/src/'
log='/var/log/uwsgi/app.log'

# uwsgi params
port=8000
processes=8
threads=8
autoreload=3
uid='www-data'
gid='www-data'

# stating apps
#pip install -U django==1.9.12
pip install -U django==1.8.17
pip uninstall -y south
pip install -e git+https://github.com/Parisson/django-jqchat.git@dj1.8#egg=django-jqchat
pip install django-debug-toolbar==1.6
pip install -e git+https://github.com/Parisson/saved_searches.git@dj1.8#egg=saved_searches-2.0.0-beta

# waiting for other network services
sh $app/scripts/wait.sh
python $manage wait-for-db

# initial setup
if [ ! -f .init ]; then
    bash $app/scripts/init.sh
    touch .init
fi

if [ $REINDEX = "True" ]; then
    python $manage rebuild_index --noinput
fi

# fix media access rights
chown -R www-data:www-data $media

# choose dev or prod mode
if [ "$1" = "--runserver" ]; then
    python $manage runserver 0.0.0.0:8000
else
    python $manage collectstatic --noinput

    # app start
    uwsgi --socket :$port --wsgi-file $wsgi --chdir $app --master \
    --processes $processes --threads $threads \
    --uid $uid --gid $gid --logto $log --touch-reload $wsgi

fi
