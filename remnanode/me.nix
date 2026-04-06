# You probably want to override this
{
    # Your username for first login
    username = "bearpro";

    # Your password (make your own by `mkpasswd -m yescrypt`)
    hashedPassword = "$y$j9T$.QS8PZgHxvYBho/cAF.if/$Iw2IOzEHXBQiCiZ.yACUJy8bm2Ba.GSKgqPPHuG79N/";

    # Your id_rsa.pub
    authorizedKeys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC1TqNEvOYQLDfhwzxj/Kus+13mWfZRX2EF+6Ds/ziXUV6W7zTjW8XBbLGO4Pp48hx4j9Tg0C5stsKPGb8OieQE1UuPvyKI78Q3Stv6mpMBgxWShYLlJmMFt7l5Zgw9WH0RrBRjZOaPFMQ9byAuOo8/wlpQx9m8Ii44NVrqnDEroZyp4TUpo0UCUHm7QWJXxQsIsC8nzwpHYDtZlfwVp6Kg4ht2qLz45pWflw1nJ5Q+nZv8LS86+Ai8AAqRArRH101cB1RROFx+zb3t5rxwAgUXDAmTyWyjlUohKgRft7UCS/1qUv/GZw5VZBidRmqKx7Ly0caEFevJ1ER76HZEWP9YWyH+cdjjYNfphIk8x9yehKufProKzay19LgNTf4ry9QU4cr+bknzIrdgjFBLaXWDHnlfWrSlUJbwH13v12Vfq5WVoO4Bjh1wyowymVG9c61c6cxoRWlw4WnG6rzy7jJRYW+Tx/cy/D52EFoIowrGb5QQkBcDAW1/zU42naJpCFE= bearpro@dt-bearpro"
    ];

    # Remnawave node paramaters
    remnaNodePort = "2222"; # Your node port
    remnaNodeSecret = "<replace with your secret>";
}