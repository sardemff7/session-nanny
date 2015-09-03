session-nanny
=============

session-nanny will help users running several sessions in parallel.

It will keep track of each session environment, and update your session-wide daemons for you.

It requires logind, a user systemd instance and D-Bus.


Features
--------

Every time you switch sessions, session-nanny will:
*   Update your systemd and D-Bus activation environments  
    This way, D-Bus-activated prompt (like PIN entry agent) will pop in the actively used session.
*   Switch your eventd notification-daemon backend  
    To always get your notifications where you need them.
*   Update your tmux environment  
    This is meant for users sharing the same tmux session over TTY/GUI sessions, so that programs you run will appear where you expect them.  
    **Note**: it does not change the environment of already running shells, but only the newly created panes and windows.


Usage
-----

session-nanny is fully D-Bus-activable, all you need to do is run the client, `session-baby`, when you login to a new session.  
You should run it if your session environment changes significantly (e.g. when you run `startx` in a TTY session).

You can inspect the current environments known to the daemon using `session-baby -d`.
