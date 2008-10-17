# A sample Apache virtual host configuration for OpacMarc.
# Modify as needed.

Listen 8081
NameVirtualHost *:8081
<VirtualHost *:8081>

    ServerName 127.0.0.1
    
    ErrorLog __LOCAL_DATA_DIR__/logs/apache-error-log
    TransferLog __LOCAL_DATA_DIR__/logs/apache-access-log
    
    DocumentRoot "__OPACMARC_DIR__/htdocs/"
    <Directory "__OPACMARC_DIR__/htdocs/">
        Order allow,deny
        Allow from all
        Options -Indexes
    </Directory>

    ScriptAlias /cgi-bin/ "__OPACMARC_DIR__/cgi-bin/"
    <Directory "__OPACMARC_DIR__/cgi-bin/">
        Order allow,deny
        Allow from all
    </Directory>
    
    # Archivos est�ticos (css, js, im�genes, etc.) locales, comunes a todas las bases
    Alias /local/ "__LOCAL_DATA_DIR__/htdocs/"
    <Directory "__LOCAL_DATA_DIR__/htdocs/">
        Order allow,deny
        Allow from all
        Options -Indexes
    </Directory>
    
    # Archivos est�ticos (css, js, im�genes, etc.) espec�ficos de cada base
    # ATENCION: aparentemente el segundo grupo ($2) debe figurar expl�citamente.
    AliasMatch "^/local-db/([^/]+)/(.+)" "__LOCAL_DATA_DIR__/bases/$1/htdocs/$2"
    <DirectoryMatch "__LOCAL_DATA_DIR__/bases/([^/]+)/htdocs/">
        Order allow,deny
        Allow from all
        Options -Indexes
    </DirectoryMatch>
 
</VirtualHost>