<#
Write a script that gets all users that are on a litigation hold, return their legal name,
user name, mailbox UPN, and - if possible - date it was placed on hold, outputs to a CSV,
and send an email to legal team (Jeff Matukewicz, Apsen Rains, Emily Lovett) with the CSV attached on a monthly basis.
Also script the removal of litigation holds (send email to legal team to notify of as well?)
#>

# gets all users that are on a litigation hold
# eturn their legal name, user name, mailbox UPN, and  date it was placed on hold
# outputs to a CSV
# send an email to legal team (Jeff Matukewicz, Apsen Rains, Emily Lovett) with the CSV attached
# setup scheduled task to email on a regular basis