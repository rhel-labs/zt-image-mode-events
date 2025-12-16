# setup proxy for access to ISO vm application
cat <<'EOF'> /etc/nginx/conf.d/proxy.conf
server {
    listen 8080;
    listen [::]:8080;

    server_name _;
        
    location / {
            resolver 192.168.122.1;
            proxy_pass http://security-vm; # Replace with your backend server's address
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
}
EOF

systemctl restart nginx.service 
