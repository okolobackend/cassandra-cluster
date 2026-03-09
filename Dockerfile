FROM cassandra:latest

# Нужно уточнить, что это антипаттерн: докер за "один процесс -- один контейнер".
# Здесь же будет два процесса
USER root

RUN apt-get update && \
    apt-get install -y openssh-server && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir /var/run/sshd

RUN useradd -m -s /bin/bash admin && \
    mkdir -p /home/admin/.ssh

# Памятка: файлы не копируются из произвольного места системы.
# Они должны быть в контексте сборки под рукой у докер-файла.
# Так как подключаться к контейнеру будем отдельным пользователем, то ему и вручаем права на ключик.
COPY authorized_keys /home/admin/.ssh/authorized_keys
RUN chown -R admin:admin /home/admin/.ssh && \
    chmod 700 /home/admin/.ssh && \
    chmod 600 /home/admin/.ssh/authorized_keys

# Хоть и работаем с антипаттерном, то хотя бы попытаемся сократить площадь для атаки:
# Поэтому запрещаем подключаться по паролям и использовать рута. Используем только ключи
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config && \
    echo "AllowUsers admin" >> /etc/ssh/sshd_config

# В скрипте запускаем ssh напрямую без судо и прочих системных управлений,
# а после возвращаем управление кассандре
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Открываем порт 22
EXPOSE 22

# В этом конкретном случае контейнер будет работать от рута,
# чтобы ssh запустился нормально. Но лучше возвращаться к пользователю кассандыр
# USER cassandra

ENTRYPOINT ["/entrypoint.sh"]
CMD []
