# Bagisto (nginx + PHP-FPM 8.4, queue worker and scheduler under Supervisor).
# Official image, pinned by version and digest. Bump both together.
FROM webkul/bagisto:2.5.1@sha256:6973b5c5c3ad11e14b2fdb2691cced4fb331ecc08d227ed27e5cd7f407f90d14

# A clean copy of storage/ (folders, import samples) without the image's own
# demo media and install marker, used to seed an empty Railway volume.
RUN cp -a /var/www/bagisto/storage /opt/bagisto-storage-seed \
 && rm -rf /opt/bagisto-storage-seed/installed \
           /opt/bagisto-storage-seed/app/public/products \
           /opt/bagisto-storage-seed/app/public/categories \
           /opt/bagisto-storage-seed/app/public/locales \
           /opt/bagisto-storage-seed/app/public/themes \
           /opt/bagisto-storage-seed/app/private/products \
           /opt/bagisto-storage-seed/logs/*.log

COPY railway-start.sh /usr/local/bin/railway-start.sh
COPY railway-install.sh /usr/local/bin/railway-install.sh
COPY railway-admin.php /usr/local/share/bagisto/railway-admin.php
RUN chmod 755 /usr/local/bin/railway-start.sh /usr/local/bin/railway-install.sh

ENV PORT=8080
EXPOSE 8080

ENTRYPOINT ["/usr/local/bin/railway-start.sh"]
CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/supervisord.conf"]
