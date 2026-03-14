let settings = { using24hr: true };
let originalHours = 8;
let originalMinutes = 0;
let weatherOnOpen = '';
let sirenSound;
let sirenReady = true;

let values = {
	hours: 8, mins: 0, weather: 'SUNNY',
	dynamic: false, freeze: false,
	instanttime: false, instantweather: false, tsunami: false,
	realtime: false, realweather: false, game_build: 0,
	weathermethod: 'game', timemethod: 'game',
	original_weathermethod: 'game', original_timemethod: 'game',
	real_info: { weather: '', weather_description: '', country: '', city: '' },
};

function post(url, data) {
	return fetch(url, { method: 'POST', body: JSON.stringify(data) }).catch(() => {});
}

function closeUI() {
	post('https://st_timer/close', {});
}

function applyChanges(vals, save) {
	post('https://st_timer/change', { values: vals, savesettings: save });
}

function convertTime(h, m) {
	return h >= 24 ? { hours: h - 24, minutes: m } : { hours: parseFloat(h), minutes: m };
}

function numToTime(n) {
	let h = Math.floor(n);
	return { hours: h, minutes: Math.floor((n - h) * 60) };
}

function generateClouds() {
	let c = document.getElementById('st-clouds');
	let b = document.getElementById('st-sky');
	let w = b.getBoundingClientRect().width;
	let h = b.getBoundingClientRect().height;
	c.innerHTML = '';
	for (let i = 0; i < 17; i++) {
		c.innerHTML += "<img src='images/weathertype/cloudy.svg' style='position:absolute; width:" +
			(Math.floor(Math.random() * 128) + 10) + "px; opacity:" + Math.random() +
			"; top:" + Math.floor(Math.random() * h - 10) + "px; left:" +
			Math.floor(Math.random() * w) + "px' class='img-fluid' />";
	}
}

function generateStars() {
	let c = document.getElementById('st-stars');
	let b = document.getElementById('st-sky');
	let w = b.getBoundingClientRect().width;
	let h = b.getBoundingClientRect().height;
	c.innerHTML = '';
	for (let i = 0; i < 33; i++) {
		c.innerHTML += "<img src='images/weathertype/stars.svg' style='position:absolute; width:" +
			Math.floor(Math.random() * 12) + "px; opacity:" + Math.random() +
			"; top:" + Math.floor(Math.random() * h - 10) + "px; left:" +
			Math.floor(Math.random() * w) + "px' class='img-fluid' />";
	}
}

function updateBackground(time) {
	let t = time.hours + time.minutes / 60;
	let sky = document.getElementById('st-sky');
	let w = sky.getBoundingClientRect().width;
	let h = sky.getBoundingClientRect().height;
	let sun = document.getElementById('st-sun');
	let moon = document.getElementById('st-moon');
	let clouds = document.getElementById('st-clouds');
	let stars = document.getElementById('st-stars');

	if (t == 0) t = 24;

	if (t >= 8 && t <= 12) {
		sky.style.backgroundColor = 'var(--st-daytime)';
		sun.style.display = 'block'; moon.style.display = 'none';
		clouds.style.display = 'block'; stars.style.display = 'none';
		let x = t - 8;
		sun.style.left = ((w * (x / 4 / 2) - 32) / w * 100) + '%';
		sun.style.bottom = ((h * (x / 4) - 32) / h * 100) + '%';
	} else if (t > 12 && t < 21) {
		sky.style.backgroundColor = 'var(--st-daytime)';
		sun.style.display = 'block'; moon.style.display = 'none';
		clouds.style.display = 'block'; stars.style.display = 'none';
		let x = t - 12;
		sun.style.left = ((w * (x / 8 / 2) - 32) / w * 100 + 50) + '%';
		sun.style.bottom = (68 - (h * (x / 8) - 32) / h * 100) + '%';
	} else if (t >= 21 && t <= 24) {
		sky.style.backgroundColor = 'var(--st-nighttime)';
		sun.style.display = 'none'; moon.style.display = 'block';
		clouds.style.display = 'none'; stars.style.display = 'block';
		let x = t - 20;
		moon.style.left = ((w * (x / 4 / 2) - 32) / w * 100) + '%';
		moon.style.bottom = ((h * (x / 4) - 32) / h * 100) + '%';
	} else {
		sky.style.backgroundColor = 'var(--st-nighttime)';
		sun.style.display = 'none'; moon.style.display = 'block';
		clouds.style.display = 'none'; stars.style.display = 'block';
		moon.style.left = ((w * (t / 7 / 2) - 32) / w * 100 + 50) + '%';
		moon.style.bottom = (68 - (h * (t / 7) - 32) / h * 100) + '%';
	}
}

function updateTimeDisplay(hours, minutes) {
	let time;
	if (hours !== undefined) {
		time = convertTime(hours, minutes);
	} else {
		let calc = numToTime(document.getElementById('st-range').value);
		time = convertTime(calc.hours, calc.minutes);
	}
	values.hours = time.hours;
	values.mins = time.minutes;
	updateBackground(time);

	let str;
	let d = new Date('1970-02-02T' +
		(time.hours < 10 ? '0' + time.hours : time.hours) + ':' +
		(time.minutes < 10 ? '0' + time.minutes : time.minutes) + ':00Z');

	if (settings.using24hr) {
		str = d.toLocaleTimeString('de-DE', { hour12: false, hour: 'numeric', minute: 'numeric', timeZone: 'UTC' });
	} else {
		str = d.toLocaleTimeString('en-US', { hour12: true, hour: 'numeric', minute: 'numeric', timeZone: 'UTC' });
	}
	document.getElementById('st-time-display').innerHTML = str;
}

function toggleWeatherInputs(disabled) {
	document.getElementById('st-dynamic').disabled = disabled;
	document.querySelectorAll("[name='st-weather']").forEach(el => el.disabled = disabled);
}

function playWarningSound() {
	if (!sirenReady) return;
	sirenReady = false;
	sirenSound.volume = 0.5;
	sirenSound.play().then(() => {
		sirenSound.currentTime = 0;
		sirenReady = true;
	});
}

function getValuesPayload() {
	return {
		weather: values.weather,
		freeze: values.freeze, dynamic: values.dynamic,
		instanttime: values.instanttime, instantweather: values.instantweather,
		tsunami: values.tsunami, realtime: values.realtime, realweather: values.realweather,
		weathermethod: values.realweather ? 'real' : 'game',
		timemethod: values.realtime ? 'real' : 'game',
	};
}

document.getElementById('st-range').addEventListener('input', () => updateTimeDisplay());

document.getElementById('st-24hr').addEventListener('click', function () {
	settings.using24hr = !settings.using24hr;
	document.getElementById('st-24hr-label').innerHTML = settings.using24hr ? '24 hr' : '12 hr';
	updateTimeDisplay(values.hours, values.mins);
});

document.addEventListener('DOMContentLoaded', function () {
	document.querySelectorAll("[data-toggle='tooltip']").forEach(el => new bootstrap.Tooltip(el, { trigger: 'hover' }));
	sirenSound = new Audio('sound/tsunami_siren.ogg');

	document.getElementById('st-card').addEventListener('animationend', function () {
		if (this.getAttribute('closing')) {
			this.style.display = 'none';
			this.removeAttribute('closing');
			this.classList.remove('slide-in-bottom', 'slide-out-bottom');
		}
	});
});

window.addEventListener('message', function (event) {
	if (event.data.action == 'open') {
		document.getElementById('st-card').style.display = 'block';
		document.getElementById('st-card').classList.add('slide-in-bottom');

		values = event.data.values;
		weatherOnOpen = values.weather;
		values.realweather = values.weathermethod === 'real';
		values.realtime = values.timemethod === 'real';

		if (values.original_weathermethod === 'game') {
			document.getElementById('realweather-toggle').style.display = 'none';
		} else if (values.real_info) {
			document.getElementById('real-city').innerHTML = values.real_info.city + ', ' + values.real_info.country;
			document.getElementById('real-weather').innerHTML = values.real_info.weather + ', ' + values.real_info.weather_description;
		}

		if (values.original_timemethod === 'game') {
			document.getElementById('realtime-toggle').style.display = 'none';
		} else if (values.real_info) {
			document.getElementById('real-city').innerHTML = values.real_info.city + ', ' + values.real_info.country;
		}

		document.querySelectorAll('.st-weather-opt').forEach(el => el.checked = false);
		document.getElementById('st-w-' + values.weather.toLowerCase()).checked = true;

		originalHours = (values.hours >= 1 && values.hours <= 7) ? values.hours + 24 : values.hours;
		originalMinutes = values.mins;
		updateTimeDisplay(originalHours, originalMinutes);

		document.getElementById('st-dynamic').checked = values.dynamic;
		document.getElementById('st-dynamic').disabled = values.realweather;
		document.getElementById('st-freeze').checked = values.freeze;
		document.getElementById('st-freeze').disabled = values.realtime;
		document.getElementById('st-instant-time').checked = values.instanttime;
		document.getElementById('st-instant-time').disabled = values.realtime;
		document.getElementById('st-instant-weather').checked = values.instantweather;
		document.getElementById('st-instant-weather').disabled = values.realweather;
		document.getElementById('st-storm').checked = values.tsunami;
		document.getElementById('st-realtime').checked = values.realtime;
		document.getElementById('st-range').disabled = values.realtime;
		document.getElementById('st-realweather').checked = values.realweather;
		toggleWeatherInputs(values.realweather);

		document.getElementById('st-range').value =
			(values.hours >= 1 && values.hours <= 7)
				? values.hours + 24 + values.mins / 60
				: values.hours + values.mins / 60;

		generateClouds();
		generateStars();

	} else if (event.data.action == 'close') {
		let card = document.getElementById('st-card');
		card.setAttribute('closing', true);
		card.classList.remove('slide-in-bottom');
		card.classList.add('slide-out-bottom');
		card.offsetWidth;
		document.querySelectorAll("[data-toggle='tooltip']").forEach(el => bootstrap.Tooltip.getInstance(el).hide());

	} else if (event.data.action == 'playsound') {
		playWarningSound();
	}
});

document.querySelectorAll('.weather-btn input, .form-check > input').forEach(el => {
	el.addEventListener('click', function () {
		if (el.value != 'on') values.weather = el.value;
	});
});

document.getElementById('st-freeze').addEventListener('click', () => values.freeze = !values.freeze);
document.getElementById('st-dynamic').addEventListener('click', () => values.dynamic = !values.dynamic);

document.getElementById('st-instant-time').addEventListener('click', function () {
	values.instanttime = !values.instanttime;
	post('https://st_timer/instanttime', { instanttime: values.instanttime });
});

document.getElementById('st-instant-weather').addEventListener('click', function () {
	values.instantweather = !values.instantweather;
	post('https://st_timer/instantweather', { instantweather: values.instantweather });
});

document.getElementById('st-storm').addEventListener('click', () => values.tsunami = !values.tsunami);

document.getElementById('st-realtime').addEventListener('click', function () {
	values.realtime = !values.realtime;
	values.timemethod = values.realtime ? 'real' : 'game';
	document.getElementById('st-range').disabled = values.realtime;
	document.getElementById('st-freeze').disabled = values.realtime;
	document.getElementById('st-instant-time').disabled = values.realtime;
});

document.getElementById('st-realweather').addEventListener('click', function () {
	values.realweather = !values.realweather;
	values.weathermethod = values.realweather ? 'real' : 'game';
	toggleWeatherInputs(values.realweather);
	document.getElementById('st-dynamic').disabled = values.realweather;
	document.getElementById('st-instant-weather').disabled = values.realweather;
	if (values.realweather && weatherOnOpen !== values.weather) {
		document.getElementById('st-w-' + weatherOnOpen.toLowerCase()).checked = true;
		document.getElementById('st-w-' + values.weather.toLowerCase()).checked = false;
	}
});

document.getElementById('st-btn-close').addEventListener('click', function () {
	window.postMessage({ action: 'close' });
	closeUI();
});

document.getElementById('st-btn-apply').addEventListener('click', function () {
	if (originalHours == values.hours && originalMinutes == values.mins) {
		applyChanges(getValuesPayload(), false);
	} else {
		applyChanges(values, false);
	}
});

document.getElementById('st-btn-save').addEventListener('click', function () {
	window.postMessage({ action: 'close' });
	if (originalHours == values.hours && originalMinutes == values.mins) {
		applyChanges(getValuesPayload(), true);
	} else {
		applyChanges(values, true);
	}
});

window.addEventListener('keydown', function (e) {
	if (e.code == 'Escape' || e.key == 'Escape') {
		window.postMessage({ action: 'close' });
		closeUI();
	}
});
