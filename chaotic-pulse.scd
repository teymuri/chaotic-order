(
// ~samp = "/home/amirt/Desktop/414437__inspectorj__dropping-metal-pin-on-wood-a.wav";
~samp = "/home/amirt/Desktop/254756__jagadamba__ceramic-bell-02.wav";
~samp2 = "/home/amirt/Desktop/621925__strangehorizon__tambourine_stick_15.wav";
b = Buffer.readChannel(s, ~samp2, channels: [0]);


SynthDef(\play, {
	arg db=0, out=0, mix=0, room=0, rate;
	var snd, env, synthdur;
	synthdur = BufDur.ir(b) * 5;
	snd = PlayBuf.ar(
		numChannels: 1,
		bufnum: b,
		// rate: BufRateScale.ir(b) * LFNoise1.kr(ratehz).range(0.005, 0.4)
		rate: BufRateScale.ir(b) * rate
	);
	env = EnvGen.kr(
		Env.perc(attackTime: 0, releaseTime: synthdur),
		levelScale: db.dbamp,
		doneAction: 2
	);
	snd = snd * env;
	snd = FreeVerb.ar(snd, mix: mix, room: room);
	Out.ar(out, snd ! 2)
}).add;

~onsetdur = {
	arg arr;
	var arr1, arr2;
	arr1 = arr.copyRange(0, arr.size - 2);
	arr2 = arr.copyRange(1, arr.size - 1);
	// arr1 = arr.select {arg x, i; i < (arr.size - 1)};
	// arr2 = arr.select {arg x, i; i > 0};
	arr2 - arr1
};

~easyDurs = [
	0.125, 0.25, 0.5,
	1,
	1/5, 2/5, 3/5, 4/5,
	1/3, 2/3,
	1/6, 5/6
]
)
(
~maxItemArrs = {
	arg arrsArr;
	arrsArr.maxItem({arg arr, i; arr.maxItem}).maxItem
};
~arrWithSmallestMaxNum = {
	arg arrs;
	arrs.minItem({arg a, i; a.maxItem})
};
~getArrIdx = {
	arg arrs, arr;
	var idx = -1;
	block {
		arg breakfun;
		arrs.do {
			arg a;
			idx = idx + 1;
			if (a == arr) {breakfun.value(idx)};
		};
		nil
	}
};
~minCommonN = {
	arg arrs, isinall;
	var smaxArr = ~arrWithSmallestMaxNum.(arrs);
	var idxToRm = ~getArrIdx.(arrs, smaxArr);
	// Modify arrs
	if (idxToRm != nil) {arrs.removeAt(idxToRm)};
	block {
		arg break;
		smaxArr[1..].do {
			arg n;
			isinall = List.new;
			arrs.do {
				arg arr;
				arr = arr[1..];
				if (arr.any({arg x, i; n.fuzzyEqual(x) >= 0.9999})) {isinall.add(true)} {isinall.add(false)};
				// [n, arr, (arr.any({arg x, i; n.fuzzyEqual(x) >= 0.99999})), isinall].postln;
			};
			if (isinall.every {arg x, i; x == true}) {break.value(n)}
		};
		nil
	}
}
)

(
~minCommonN.([
	[0,1,22,3,4,5,6],
	[0,1,2,22,3,33],
	[0,222,5,23]
]);
)
(
~minCommonN.([
	Array.series(12, 0, 3/5)
	,
	Array.series(15, 0, 2/4)
]);
)


(
// get the wait times
// je größer chaosgap, desto mehr Abstand zwischen Chaos Hits
~onsets = {
	arg deltas, chaosmaxgap=1, chaosstepsz=4,
	// cut heisst: nur bis dahin wo die rhythmen sich wieder treffen
	// cut=true,
	repeats=1 // wie oft die eine Periode wiederholen
	;
	var akks_list=List.new, waitArr;
	var sz = 1000; // oder noch groeßr, muss groß genug sein, eg inf
	// alle Akkzente
	var akk_arrs = deltas.collect {
		arg delta;
		Array.series(sz, 0.0, delta);
	};
	var mincommonN, mincommonidx;
	// save a cp, as removeAt in ~minCommonN fucks the arg!!!! :-(
	var akkarrscp = List.new;
	akk_arrs.do {
		arg akkarr;
		akkarrscp.add(akkarr)
	};
	mincommonN = ~minCommonN.(akkarrscp) * repeats;
	"min common number >>> %\n".postf(mincommonN);

	akk_arrs.do {
		arg akk_arr;
		mincommonidx = akk_arr.indexOfEqual(mincommonN);
		akks_list = akks_list ++ (akk_arr[..mincommonidx]);
		/*if (cut) {
		} {
			akks_list = akks_list ++ akk_arr;
		}*/
	};
	akks_list = akks_list.asSet.asArray.sort;
	waitArr = List.new;
	waitArr = waitArr ++ akks_list;
	// add random hits
	akks_list.do {
		arg akk, i;
		if (
			i < (akks_list.size - 1),
			{
				var tempchaoticarr, next_akk_wait, tmpakk = akk; // akk ist immutable...
				tempchaoticarr = Array.linrand(chaosstepsz, 0.0, chaosmaxgap).collect {
				// tempchaoticarr = Array.fill(chaosstepsz, {~easyDurs.choose}).collect {
					arg rndwait;
					akk = akk + rndwait;
				};
				waitArr = waitArr ++ tempchaoticarr.select({arg x; x < akks_list[i+1]});
			}
		)
	};
	// akks_list.postln;
	// waitArr.asSet.asList.sort.postln;
	[waitArr.asSet.asList.sort, akks_list]
}
)
~onsets.([3/5, 2/4], chaosmaxgap: 1, repeats: 2)
[1,2,3,4,5][..(1+1)]
[1,2,3,4][..([1,2,3,4].indexOf(2))]


(
var chaosDb = -inf;
var xxx, arrsum;
// var r = 0.1.exprand(0.11);
#xxx, arrsum = ~onsets.(
	[1/2, 4/5, 1/3],
	// chaosmaxgap: 3,
	chaosstepsz: 1,
	// cut: true,
	repeats: 4
);
// arrsum.postln;
Task({
	var ws = ~onsetdur.(xxx);
	var db, mix, room;
	[xxx, ws.sum].postln;
	ws.do {
		arg w, i;
		db = if (arrsum.indexOfEqual(xxx[i]) != nil, 0, chaosDb);
		mix = if (db >= 0, {1}, {0});
		room = if (db >= 0, {1}, {0});
		// [w,db].postln;
		Synth(\play, [db: db, mix: 0.5, room: rrand(0.1, 0.4), rate: 0.4]);
		w.wait;
	};
}).play
)
