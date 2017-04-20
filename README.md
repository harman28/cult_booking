# cult_booking

My friend Harshit appears to have discipline, so he can get his Cult classes booked according a schedule. The rest of us can only hope.

### Setting Up
```sh
cp schedules/harshit.json.sample schedules/harshit.json
```
A cronjob on a remote machine will run this script every 3 hours or so. The log files will be hosted over a web server.
```sh
0 */3 * * * ruby /home/harman/cult_booking/booking.rb
```
If you want your classes booked too, and can't bother setting this up, open a pull request with a file like the one in `schedules/harshit.json.sample`. Plenty of room for everyone.

### Todo
- This is awfully binary. I mean if you're not getting the 7pm Boxing class, why not book the 8pm one instead?
- What if Harshit wants to do multiple classes a day? Who's going to book those?
