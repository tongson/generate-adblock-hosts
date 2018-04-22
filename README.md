# generate-adblock-hosts
Generate list of hosts to block for dnsmasq and unbound

# Compile

    $ cd generate-adblock-hosts
    $ make
    $ bin/gen

# Files

Generated files are `dnsmasq.conf` and `unbound.conf`.

# How to use with dnsmasq

Use the generated file `dnsmasq.conf` as a directive to `addn-hosts`.

    addn-hosts=/etc/adblock/dnsmasq.conf


# How to use with unbound

Include the generated file `unbound.conf` under the server section.

    server:
        include: /etc/adblock/unbound.conf


