Date.prototype.convertUTCTimeToLocalTime = function (utcDateTime) {
    var localDateTime = new Date();
    var offsetMS = localDateTime.getTimezoneOffset() * 60000;
    var utcTime = utcDateTime.getTime();
    var localTime = utcTime + offsetMS*-1;

    var convertedDateTime = new Date(localTime);

    return convertedDateTime;
};

Date.prototype.isDayLightTime = function () {
    var d = this;

    var d_s = new Date(d.getTime());
    d_s.setMonth(0);
    d_s.setDate(1);
    d_s.setHours(0);
    d_s.setMinutes(0);
    d_s.setSeconds(0);

    var d_m = new Date(d_s.getTime());
    d_m.setMonth(6);

    if ((d_m.getTimezoneOffset() - d_s.getTimezoneOffset()) == 0)
        return false;

    return true;
};

// a global month names array
var gsMonthNames = new Array(
'January',
'February',
'March',
'April',
'May',
'June',
'July',
'August',
'September',
'October',
'November',
'December'
);
// a global day names array
var gsDayNames = new Array(
'Sunday',
'Monday',
'Tuesday',
'Wednesday',
'Thursday',
'Friday',
'Saturday'
);
// the date format prototype
Date.prototype.format = function (f) {
    if (!this.valueOf())
        return '&nbsp;';

    var d = this;

    return f.replace(/(yyyy|mmmm|mmm|mm|dddd|ddd|dd|hh|nn|ss|a\/p)/gi,
        function ($1) {
            switch ($1.toLowerCase()) {
                case 'yyyy': return d.getFullYear();
                case 'mmmm': return gsMonthNames[d.getMonth()];
                case 'mmm': return gsMonthNames[d.getMonth()].substr(0, 3);
                case 'mm': return (d.getMonth() + 1).zp(2);
                case 'dddd': return gsDayNames[d.getDay()];
                case 'ddd': return gsDayNames[d.getDay()].substr(0, 3);
                case 'dd': return d.getDate().zp(2);
                case 'hh': return d.getHours().zp(2);
                case 'nn': return d.getMinutes().zp(2);
                case 'ss': return d.getSeconds().zp(2);
                case 'a/p': return d.getHours() < 12 ? 'a' : 'p';
            }
        }
    );
};