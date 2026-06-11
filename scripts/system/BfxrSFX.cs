using Godot;
using System;
using System.Runtime.InteropServices;
using System.Threading.Tasks;
using AudioStreamWAV = Godot.AudioStreamWav;

/// <summary>
/// BfxrSFX — Godot 4 C# port of the Bfxr sound effect generator.
/// Bfxr by increpare (Stephen Lavelle), based on sfxr by DrPetter (Thomas Vian).
///
/// Wave types:
///   0=Square  1=Saw  2=Sine   3=White  4=Triangle
///   5=Rasp    6=Tan  7=Whistle  8=Breaker  9=Bitnoise  10=FMSyn  11=Voice
///
/// Changes from original:
///   • Random helpers now use System.Random.Shared (lock-free, thread-safe).
///   • Generate() refactored into GenerateFromSnapshot() + BuildWav() to support threading.
///   • BfxrParamSnapshot struct snapshots all Godot Dictionary values into plain C# value
///     types before any background work, keeping Godot object access on the main thread.
///   • GenerateWav()      — public synchronous generation (call from main thread).
///   • GenerateWavAsync() — fire-and-forget: synthesis runs on a Task, result delivered
///     to the main thread via Callable.CallDeferred so the AudioStreamWAV is always
///     created and played on the main thread.
///
/// Corrections vs first port:
///   • SuperSampleCount raised from 4 to 8 to match the original JS inner loop.
///     4x caused every pitch to be generated one octave too low; the amplitude
///     normaliser (1/SuperSampleCount) compensates automatically when changed.
///     To revert to 4x for performance, set SuperSampleCount = 4. The pitch will
///     drop an octave but everything else will remain correct.
///   • Wave types 5 (Rasp), 10 (FMSyn), and 11 (Voice) now use the original
///     Adventure Kid Waveform (AKWF) single-cycle lookup tables instead of
///     mathematical approximations. The JS implementation always used these tables;
///     the approximations were audibly wrong for any sound using those wave types.
///     Tables are stored as ushort[] (0..65535 unsigned) and normalised to [-1,1]
///     identically to the JS: value / 32768f - 1f.
/// </summary>
[GlobalClass]
public partial class BfxrSFX : Node
{
	private const int SampleRate       = 44100;
	private const int PoolSize         = 8;
	private const int LoResNoisePeriod = 8;

	/// <summary>
	/// Inner supersampling iterations per output sample.
	/// 8 matches the original JS and gives correct pitch.
	/// 4 is faster but produces every pitch one octave too low.
	/// The volume normaliser (1/SuperSampleCount) adjusts automatically.
	/// </summary>
	private const int SuperSampleCount = 8;

	private readonly AudioStreamPlayer[] _players = new AudioStreamPlayer[PoolSize];
	private int _poolIdx;

	public override void _Ready()
	{
		for (int i = 0; i < PoolSize; i++)
		{
			var player = new AudioStreamPlayer();
			AddChild(player);
			_players[i] = player;
		}
	}

	// ─────────────────────────────────────────────────────────────────────────
	//  PUBLIC GENERATION API  (called by AudioManager / VoiceProfile)
	// ─────────────────────────────────────────────────────────────────────────

	/// <summary>
	/// Synchronously generate and return an AudioStreamWAV from the given params.
	/// Safe to call from the main thread; suitable for editor previews.
	/// </summary>
	public AudioStreamWAV GenerateWav(Godot.Collections.Dictionary p)
		=> Generate(p);


	public void GenerateWavAsync(Node target, string methodName, int callbackId, Godot.Collections.Dictionary p)
	{
		FillDefaults(p);
		var snap = new BfxrParamSnapshot(p);

		Task.Run(() =>
		{
			try
			{
				var (bytes, usedBytes) = GenerateFromSnapshot(snap);
				Callable.From(() =>
				{
					try   { target.Call(methodName, callbackId, BuildWav(bytes, usedBytes)); }
					catch (Exception ex) { GD.PushError($"BfxrSFX callback error: {ex.Message}"); }
				}).CallDeferred();
			}
			catch (Exception ex) { GD.PushError($"BfxrSFX generation error: {ex.Message}"); }
		});
	}

	// ─────────────────────────────────────────────────────────────────────────
	//  EXISTING PUBLIC PLAY API  (unchanged)
	// ─────────────────────────────────────────────────────────────────────────

	public void Play(Godot.Collections.Dictionary p)
	{
		var wav    = Generate(p);
		var player = _players[_poolIdx % PoolSize];
		_poolIdx++;
		player.Stream = wav;
		player.Play();
	}

	public void PlayPickup()
	{
		var p = Defaults();
		p["frequency_start"]         = RandF(0.4f, 0.9f);
		p["sustainTime"]             = Randf() * 0.1f;
		p["decayTime"]               = RandF(0.1f, 0.5f);
		p["sustainPunch"]            = RandF(0.3f, 0.6f);
		if (Randf() < 0.5f)
		{
			p["pitch_jump_repeat_speed"] = RandF(0.5f, 0.7f);
			int cnum = RandI(1, 7);
			p["pitch_jump_amount"] = (float)cnum / (float)RandI(cnum + 2, cnum + 9);
		}
		Play(p);
	}

	public void PlayLaser()
	{
		var p = Defaults();
		p["waveType"] = RandN(3);
		if ((int)p["waveType"] == 2 && Randf() < 0.5f)
			p["waveType"] = RandN(2);
		if (Randf() < 0.33f)
		{
			p["frequency_start"] = RandF(0.1f, 0.6f);
			p["min_frequency_relative_to_starting_frequency"] = Randf() * 0.1f;
			p["frequency_slide"]  = RandF(-0.65f, -0.35f);
		}
		else
		{
			p["frequency_start"] = RandF(0.5f, 1.0f);
			p["min_frequency_relative_to_starting_frequency"] =
				Mathf.Max(0.2f, (float)p["frequency_start"] - 0.2f - Randf() * 0.6f);
			p["frequency_slide"] = RandF(-0.35f, -0.15f);
		}
		if ((float)p["frequency_start"] < 0.15f)
		{
			p["min_frequency_relative_to_starting_frequency"] = 0.0f;
			p["frequency_slide"] = RandF(-0.2f, -0.1f);
		}
		if (Randf() < 0.5f)
		{
			p["squareDuty"] = Randf() * 0.5f;
			p["dutySweep"]  = Randf() * 0.2f;
		}
		else
		{
			p["squareDuty"] = RandF(0.4f, 0.9f);
			p["dutySweep"]  = -Randf() * 0.7f;
		}
		p["sustainTime"] = RandF(0.1f, 0.3f);
		p["decayTime"]   = Randf() * 0.4f;
		if (Randf() < 0.50f) p["sustainPunch"]  = Randf() * 0.3f;
		if (Randf() < 0.33f) { p["flangerOffset"] = Randf() * 0.2f; p["flangerSweep"] = -Randf() * 0.2f; }
		if (Randf() < 0.50f) p["hpFilterCutoff"] = Randf() * 0.3f;
		Play(p);
	}

	public void PlayExplosion()
	{
		var p = Defaults();
		p["waveType"] = Randf() < 0.5f ? 3 : 9;
		if (Randf() < 0.5f)
		{
			p["frequency_start"] = RandF(0.1f, 0.5f);
			p["frequency_slide"] = RandF(-0.1f, 0.3f);
		}
		else
		{
			p["frequency_start"] = RandF(0.2f, 0.9f);
			p["frequency_slide"] = RandF(-0.4f, -0.2f);
		}
		float fs = (float)p["frequency_start"];
		p["frequency_start"] = fs * fs;
		if (Randf() < 0.20f) p["frequency_slide"] = 0.0f;
		if (Randf() < 0.33f) p["repeatSpeed"] = RandF(0.3f, 0.8f);
		p["sustainTime"]  = RandF(0.1f, 0.4f);
		p["decayTime"]    = Randf() * 0.5f;
		p["sustainPunch"] = RandF(0.2f, 0.8f);
		if (Randf() < 0.50f) { p["flangerOffset"] = RandF(-0.3f, 0.6f); p["flangerSweep"] = -Randf() * 0.3f; }
		if (Randf() < 0.33f) { p["pitch_jump_repeat_speed"] = RandF(0.6f, 0.9f); p["pitch_jump_amount"] = RandF(-0.8f, 0.8f); }
		Play(p);
	}

	public void PlayPowerup()
	{
		var p = Defaults();
		if (Randf() < 0.5f) p["waveType"]   = 1;
		else                    p["squareDuty"] = Randf() * 0.6f;
		if (Randf() < 0.5f)
		{
			p["frequency_start"] = RandF(0.2f, 0.5f);
			p["frequency_slide"] = RandF(0.1f, 0.5f);
			p["repeatSpeed"]     = RandF(0.4f, 0.8f);
		}
		else
		{
			p["frequency_start"] = RandF(0.2f, 0.5f);
			p["frequency_slide"] = RandF(0.05f, 0.25f);
			if (Randf() < 0.5f) { p["vibratoDepth"] = Randf() * 0.7f; p["vibratoSpeed"] = Randf() * 0.6f; }
		}
		p["sustainTime"] = Randf() * 0.4f;
		p["decayTime"]   = RandF(0.1f, 0.5f);
		Play(p);
	}

	public void PlayHit()
	{
		var p = Defaults();
		int[] types = { 3, 9, 1, 0, 11 };
		p["waveType"] = types[RandN(types.Length)];
		if ((int)p["waveType"] == 0) p["squareDuty"] = Randf() * 0.6f;
		p["frequency_start"] = RandF(0.2f, 0.8f);
		p["frequency_slide"] = RandF(-0.7f, -0.3f);
		p["sustainTime"] = Randf() * 0.1f;
		p["decayTime"]   = RandF(0.1f, 0.3f);
		if (Randf() < 0.5f) p["hpFilterCutoff"] = Randf() * 0.3f;
		Play(p);
	}

	public void PlayJump()
	{
		var p = Defaults();
		int[] types = { 0, 1, 10 };
		p["waveType"]        = types[RandN(types.Length)];
		p["squareDuty"]      = Randf() * 0.6f;
		p["frequency_start"] = RandF(0.3f, 0.6f);
		p["frequency_slide"] = RandF(0.1f, 0.3f);
		p["sustainTime"] = RandF(0.1f, 0.4f);
		p["decayTime"]   = RandF(0.1f, 0.3f);
		if (Randf() < 0.5f) p["hpFilterCutoff"] = Randf() * 0.3f;
		if (Randf() < 0.5f) p["lpFilterCutoff"] = RandF(0.4f, 1.0f);
		Play(p);
	}

	public void PlayBlip()
	{
		var p = Defaults();
		int[] types = { 0, 1, 10, 7 };
		p["waveType"] = types[RandN(types.Length)];
		if ((int)p["waveType"] == 0) p["squareDuty"] = Randf() * 0.6f;
		p["frequency_start"] = RandF(0.2f, 0.6f);
		p["sustainTime"]     = RandF(0.1f, 0.2f);
		p["decayTime"]       = Randf() * 0.2f;
		p["hpFilterCutoff"]  = 0.1f;
		Play(p);
	}

	public void PlayRandom()
	{
		var p = Defaults();
		RandomizeParams(p);
		Play(p);
	}

	public Godot.Collections.Dictionary Mutate(Godot.Collections.Dictionary p)
	{
		var result = p.Duplicate();
		FillDefaults(result);
		string[] nudgeKeys = {
			"frequency_start", "frequency_slide", "frequency_acceleration",
			"sustainTime", "decayTime", "sustainPunch", "attackTime",
			"vibratoDepth", "vibratoSpeed", "squareDuty", "dutySweep",
			"flangerOffset", "flangerSweep", "lpFilterCutoff",
			"hpFilterCutoff", "bitCrush", "repeatSpeed", "overtones",
		};
		foreach (var k in nudgeKeys)
			result[k] = Mathf.Clamp((float)result[k] + RandF(-0.05f, 0.05f), 0.0f, 1.0f);
		return result;
	}

	// ─────────────────────────────────────────────────────────────────────────
	//  INTERNAL GENERATION PIPELINE
	// ─────────────────────────────────────────────────────────────────────────

	/// <summary>Synchronous internal path used by Play* preset methods.</summary>
	private static AudioStreamWAV Generate(Godot.Collections.Dictionary p)
	{
		FillDefaults(p);
		var snap = new BfxrParamSnapshot(p);
		var (bytes, usedBytes) = GenerateFromSnapshot(snap);
		return BuildWav(bytes, usedBytes);
	}

	/// <summary>Wrap raw bytes into an AudioStreamWAV. Must run on the main thread.</summary>
	private static AudioStreamWAV BuildWav(byte[] bytes, int usedBytes)
	{
		var wav = new AudioStreamWAV();
		wav.Format  = AudioStreamWAV.FormatEnum.Format16Bits;
		wav.MixRate = SampleRate;
		wav.Stereo  = false;
		wav.Data    = usedBytes < bytes.Length ? bytes[..usedBytes] : bytes;
		return wav;
	}

	// ─────────────────────────────────────────────────────────────────────────
	//  SYNTHESIS ENGINE
	// ─────────────────────────────────────────────────────────────────────────

	private static (byte[] bytes, int usedBytes) GenerateFromSnapshot(BfxrParamSnapshot s)
	{
		// ── Derive locals from snapshot ───────────────────────────────────────
		float masterVol    = s.MasterVolume; masterVol *= masterVol;
		int   waveType     = s.WaveType;
		float sustainPunch = s.SustainPunch;
		float comprAmt     = s.CompressionAmount;
		float compress     = 1.0f / (1.0f + 4.0f * comprAmt);
		bool  useCompr     = comprAmt > 0.0f;

		float envLen0 = s.AttackTime;  envLen0 = envLen0 * envLen0 * 100000.0f;
		float envLen1 = s.SustainTime; envLen1 = envLen1 * envLen1 * 100000.0f;
		float envLen2 = s.DecayTime;   envLen2 = envLen2 * envLen2 * 100000.0f + 10.0f;
		int   fullLen = (int)(envLen0 + envLen1 + envLen2);
		float over0   = envLen0 > 0.0f ? 1.0f / envLen0 : 0.0f;
		float over1   = envLen1 > 0.0f ? 1.0f / envLen1 : 0.0f;
		float over2   = envLen2 > 0.0f ? 1.0f / envLen2 : 0.0f;

		int   overtones = (int)(s.Overtones * 10.0f);
		float otFalloff = s.OvertoneFalloff;

		float freqStart      = s.FrequencyStart;
		double freqPeriodInit = 100.0 / (freqStart * freqStart + 0.001);
		float minFreq        = s.MinFrequencyRelative;
		float minFreqActual  = MathF.Pow(minFreq, 0.4f) * freqStart;
		double freqMaxPeriod  = 100.0 / (minFreqActual * minFreqActual + 0.001);
		if (waveType == 9)
		{
			float sf2 = 0.5f + freqStart;
			float mf2 = 0.495f + minFreq / 0.99f;
			freqPeriodInit = 100.0f / (sf2 * sf2 + 0.001f);
			freqMaxPeriod  = 100.0f / (mf2 * mf2 + 0.001f);
		}
		double freqPeriod = freqPeriodInit;

		float pFs      = s.FrequencySlide;
		float pFa      = s.FrequencyAcceleration;
		double slide    = 1.0 - pFs * pFs * pFs * 0.01;
		double freqAccl = -(double)pFa * pFa * pFa * 0.000001;

		float vibSpeed = s.VibratoSpeed; vibSpeed = vibSpeed * vibSpeed * 0.01f;
		float vibAmp   = s.VibratoDepth * 0.5f;
		float vibPhase = 0.0f;

		float sqDutyBase  = s.SquareDuty;
		float sqSweepBase = s.DutySweep;
		float sqDuty      = 0.5f - sqDutyBase * 0.5f;
		float sqSweep     = -sqSweepBase * 0.00005f;

		float repeatPeriod = Mathf.Lerp(fullLen, (float)SampleRate / 10.0f, s.RepeatSpeed);
		float repeatTimer  = 0.0f;

		float pjRepLen  = Mathf.Lerp(fullLen, (float)SampleRate / 50.0f, s.PitchJumpRepeatSpeed) + 32.0f;
		float pjWin     = pjRepLen > 0.0f ? pjRepLen : fullLen;
		float pj1v      = s.PitchJumpAmount;
		float pj2v      = s.PitchJump2Amount;
		float pj1Amount = pj1v > 0.0f ? 1.0f - pj1v * pj1v * 0.9f : 1.0f + pj1v * pj1v * 10.0f;
		float pj2Amount = pj2v > 0.0f ? 1.0f - pj2v * pj2v * 0.9f : 1.0f + pj2v * pj2v * 10.0f;
		float pjOnset1  = s.PitchJumpOnsetPercent;
		float pjOnset2  = s.PitchJumpOnset2Percent;
		float pj1Ts     = pjOnset1 != 1.0f ? pjOnset1 * pjWin + 32.0f : 0.0f;
		float pj2Ts     = pjOnset2 != 1.0f ? pjOnset2 * pjWin + 32.0f : 0.0f;
		float pjTimer   = 0.0f;
		bool  pj1Hit    = false;
		bool  pj2Hit    = false;

		float pFo           = s.FlangerOffset;
		float pFs2          = s.FlangerSweep;
		bool  useFlanger    = pFo != 0.0f || pFs2 != 0.0f;
		float flangerOffset = pFo * pFo * 1020.0f; if (pFo < 0.0f) flangerOffset = -flangerOffset;
		float flangerDelta  = pFs2 * pFs2 * pFs2 * 0.2f;
		int   flangerPos    = 0;
		int   flangerInt    = 0;
		float[] flangerBuf  = new float[1024];

		float pLp  = s.LpFilterCutoff;
		float pLps = s.LpFilterCutoffSweep;
		float pLpr = s.LpFilterResonance;
		float pH   = s.HpFilterCutoff;
		float pHps = s.HpFilterCutoffSweep;
		bool  useFilters = pLp != 1.0f || pH != 0.0f;
		bool  lpOn       = pLp != 1.0f;
		float lpCutoff   = pLp * pLp * pLp * 0.1f;
		float lpDcut     = 1.0f + pLps * 0.0001f;
		float lpDamp     = 5.0f / (1.0f + pLpr * pLpr * 20.0f) * (0.01f + lpCutoff);
		if (lpDamp > 0.8f) lpDamp = 0.8f;
		lpDamp = 1.0f - lpDamp;
		float lpPos    = 0.0f;
		float lpDpos   = 0.0f;
		float hpPos    = 0.0f;
		float hpCutoff = pH * pH * 0.1f;
		float hpDcut   = 1.0f + pHps * 0.0003f;

		float pBc     = s.BitCrush;
		float pBcs    = s.BitCrushSweep;
		float bcFreq  = 1.0f - MathF.Pow(pBc, 1.0f / 3.0f);
		float bcSweep = fullLen > 0 ? -pBcs / fullLen : 0.0f;
		float bcPhase = 0.0f;
		float bcLast  = 0.0f;

		float[] noiseBuf = new float[32];
		float[] loResBuf = new float[32];
		for (int i = 0; i < 32; i++) noiseBuf[i] = RandNoise();
		loResBuf[0] = RandNoise();
		for (int i = 1; i < 32; i++)
			loResBuf[i] = (i % LoResNoisePeriod) == 0 ? RandNoise() : loResBuf[i - 1];

		int   oneBitState = 1 << 14;
		float oneBitVal   = 0.0f;

		// ── Envelope state ────────────────────────────────────────────────────
		int   envStage  = 0;
		float envTime   = 0.0f;
		float envVol    = 0.0f;
		float attackLen = envLen0;

		// ── Phase & period cache ──────────────────────────────────────────────
		int   phase      = 0;
		int   periodTemp = 8;
		float invPeriod  = 1.0f / 8.0f;
		int   lastPeriod = -1;

		// ── Output buffer ─────────────────────────────────────────────────────
		byte[] bytes      = new byte[fullLen * 2];
		int    usedBytes  = fullLen * 2;
		int    lastNonzero = 0;
		bool   muted      = false;

		var sampleSpan = MemoryMarshal.Cast<byte, short>(bytes.AsSpan());

		// ═════════════════════════════════════════════════════════════════════
		//  MAIN LOOP
		// ═════════════════════════════════════════════════════════════════════
		for (int i = 0; i < fullLen; i++)
		{
			// ── Repeat / partial reset ────────────────────────────────────────
			repeatTimer += 1.0f;
			if (repeatTimer >= repeatPeriod && repeatPeriod > 0.0f)
			{
				repeatTimer   = 0.0f;
				freqPeriod    = freqPeriodInit;
				slide         = 1.0f - pFs * pFs * pFs * 0.01f;
				freqAccl      = -pFa * pFa * pFa * 0.000001f;
				flangerOffset = pFo * pFo * 1020.0f; if (pFo < 0.0f) flangerOffset = -flangerOffset;
				bcFreq        = 1.0f - MathF.Pow(pBc, 1.0f / 3.0f);
				if (waveType == 0)
				{
					sqDuty  = 0.5f - sqDutyBase * 0.5f;
					sqSweep = -sqSweepBase * 0.00005f;
				}
				lpCutoff = pLp * pLp * pLp * 0.1f;
				lpDcut   = 1.0f + pLps * 0.0001f;
				lpDamp   = 5.0f / (1.0f + pLpr * pLpr * 20.0f) * (0.01f + lpCutoff);
				if (lpDamp > 0.8f) lpDamp = 0.8f;
				lpDamp   = 1.0f - lpDamp;
				hpCutoff = pH * pH * 0.1f;
				hpDcut   = 1.0f + pHps * 0.0003f;
				pj1Hit   = false;
				pj2Hit   = false;
				lastPeriod = -1;
			}

			// ── Pitch-jump timers ─────────────────────────────────────────────
			pjTimer += 1.0f;
			if (pjTimer >= pjRepLen)
			{
				pjTimer = 0.0f;
				if (pj1Hit) { freqPeriod /= pj1Amount; pj1Hit = false; }
				if (pj2Hit) { freqPeriod /= pj2Amount; pj2Hit = false; }
			}
			if (!pj1Hit && pjTimer >= pj1Ts) { pj1Hit = true; freqPeriod *= pj1Amount; }
			if (!pj2Hit && pjTimer >= pj2Ts) { pj2Hit = true; freqPeriod *= pj2Amount; }

			// ── Frequency slide + acceleration ────────────────────────────────
			slide      += freqAccl;
			freqPeriod *= slide;
			if (freqPeriod > freqMaxPeriod)
			{
				freqPeriod = freqMaxPeriod;
				if (minFreq > 0.0f) muted = true;
			}

			// ── Period with optional vibrato ──────────────────────────────────
			int newPeriod = (int)freqPeriod;
			if (vibAmp > 0.0f)
			{
				vibPhase  += vibSpeed;
				newPeriod  = (int)(freqPeriod * (1.0f + MathF.Sin(vibPhase) * vibAmp));
			}
			if (newPeriod < 8) newPeriod = 8;

			if (newPeriod != lastPeriod)
			{
				lastPeriod = newPeriod;
				periodTemp = newPeriod;
				invPeriod  = 1.0f / newPeriod;
			}

			// ── Square duty sweep ─────────────────────────────────────────────
			if (waveType == 0)
			{
				sqDuty += sqSweep;
				if      (sqDuty < 0.001f) sqDuty = 0.001f;
				else if (sqDuty > 0.500f) sqDuty = 0.500f;
			}

			// ── Envelope ──────────────────────────────────────────────────────
			envTime += 1.0f;
			if (envTime > attackLen)
			{
				envTime = 0.0f;
				envStage++;
				if      (envStage == 1) attackLen = envLen1;
				else if (envStage == 2) attackLen = envLen2;
			}
			switch (envStage)
			{
				case 0:  envVol = envTime * over0; break;
				case 1:  envVol = 1.0f + (1.0f - envTime * over1) * 2.0f * sustainPunch; break;
				case 2:  envVol = 1.0f - envTime * over2; break;
				default: envVol = 0.0f; break;
			}

			// ── Flanger offset update ─────────────────────────────────────────
			if (useFlanger)
			{
				flangerOffset += flangerDelta;
				flangerInt     = (int)flangerOffset;
				if      (flangerInt <    0) flangerInt = -flangerInt;
				else if (flangerInt > 1023) flangerInt = 1023;
			}

			// ── HP filter cutoff sweep ────────────────────────────────────────
			if (useFilters)
			{
				hpCutoff *= hpDcut;
				if      (hpCutoff < 0.00001f) hpCutoff = 0.00001f;
				else if (hpCutoff > 0.100f)   hpCutoff = 0.100f;
			}

			// ═════════════════════════════════════════════════════════════════
			//  SUPERSAMPLING INNER LOOP
			//  SuperSampleCount = 8 matches the original JS.
			//  Change to 4 for performance (pitch drops one octave).
			// ═════════════════════════════════════════════════════════════════
			float superSample = 0.0f;

			for (int j = 0; j < SuperSampleCount; j++)
			{
				phase++;
				if (phase >= periodTemp)
				{
					phase -= periodTemp;
					switch (waveType)
					{
						case 3:
							for (int n = 0; n < 32; n++) noiseBuf[n] = RandNoise();
							break;
						case 6:
							loResBuf[0] = RandNoise();
							for (int n = 1; n < 32; n++)
								loResBuf[n] = (n % LoResNoisePeriod) == 0
									? RandNoise() : loResBuf[n - 1];
							break;
						case 9:
							int fb = ((oneBitState >> 1) & 1) ^ (oneBitState & 1);
							oneBitState = (oneBitState >> 1) | (fb << 14);
							oneBitVal   = (~oneBitState & 1) - 0.5f;
							break;
					}
				}

				float norm = phase * invPeriod;
				float sample;

				if (overtones == 0)
				{
					switch (waveType)
					{
						case 0:
							sample = norm < sqDuty ? 0.5f : -0.5f;
							break;
						case 1:
							sample = 1.0f - norm * 2.0f;
							break;
						case 2:
						{
							float pos = norm > 0.5f ? (norm - 1.0f) * Mathf.Tau : norm * Mathf.Tau;
							float ts  = pos < 0.0f
								? 1.27323954f * pos + 0.405284735f * pos * pos
								: 1.27323954f * pos - 0.405284735f * pos * pos;
							sample = ts < 0.0f
								? 0.225f * (ts * -ts - ts) + ts
								: 0.225f * (ts *  ts - ts) + ts;
							break;
						}
						case 3:
							sample = noiseBuf[(int)(norm * 32.0f) & 31];
							break;
						case 4:
							sample = MathF.Abs(1.0f - norm * 2.0f) - 1.0f;
							break;
						// ── AKWF wavetable lookups (types 5, 10, 11) ─────────────────────
						// Identical to the JS: index = floor(norm * 256) & 255
						//                     sample = table[index] / 32768 - 1
						case 5:
							sample = Akwf_granular_0044[(int)(norm * 256f) & 255] / 32768f - 1f;
							break;
						case 6:
						{
							float tv = MathF.Tan(MathF.PI * norm);
							sample = (tv < 4.0f && tv > -4.0f) ? tv : (tv > 0.0f ? 4.0f : -4.0f);
							break;
						}
						case 7:
						{
							float wp  = norm > 0.5f ? (norm - 1.0f) * Mathf.Tau : norm * Mathf.Tau;
							float wts = wp < 0.0f
								? 1.27323954f * wp + 0.405284735f * wp * wp
								: 1.27323954f * wp - 0.405284735f * wp * wp;
							float wsv = wts < 0.0f
								? 0.225f * (wts * -wts - wts) + wts
								: 0.225f * (wts *  wts - wts) + wts;
							sample = 0.75f * wsv;
							float w2  = (phase * 20.0f % periodTemp) * invPeriod;
							w2 = w2 > 0.5f ? (w2 - 1.0f) * Mathf.Tau : w2 * Mathf.Tau;
							float wts2 = w2 < 0.0f
								? 1.27323954f * w2 + 0.405284735f * w2 * w2
								: 1.27323954f * w2 - 0.405284735f * w2 * w2;
							float wsv2 = wts2 < 0.0f
								? 0.225f * (wts2 * -wts2 - wts2) + wts2
								: 0.225f * (wts2 *  wts2 - wts2) + wts2;
							sample += 0.25f * wsv2;
							break;
						}
						case 8:
							sample = MathF.Abs(1.0f - norm * norm * 2.0f) - 1.0f;
							break;
						case 9:
							sample = oneBitVal;
							break;
						case 10:
							sample = Akwf_fmsynth_0012[(int)(norm * 256f) & 255] / 32768f - 1f;
							break;
						case 11:
							sample = Akwf_hvoice_0012[(int)(norm * 256f) & 255] / 32768f - 1f;
							break;
						default: sample = 0.0f; break;
					}
				}
				else
				{
					sample = 0.0f;
					float otStr = 1.0f;
					for (int k = 0; k <= overtones; k++)
					{
						int   tp = (phase * (k + 1)) % periodTemp;
						float tn = tp * invPeriod;
						switch (waveType)
						{
							case 0:  sample += otStr * (tn < sqDuty ? 0.5f : -0.5f); break;
							case 1:  sample += otStr * (1.0f - tn * 2.0f); break;
							case 2:
							{
								float p2  = tn > 0.5f ? (tn - 1.0f) * Mathf.Tau : tn * Mathf.Tau;
								float ts2 = p2 < 0.0f
									? 1.27323954f * p2 + 0.405284735f * p2 * p2
									: 1.27323954f * p2 - 0.405284735f * p2 * p2;
								sample += otStr * (ts2 < 0.0f
									? 0.225f * (ts2 * -ts2 - ts2) + ts2
									: 0.225f * (ts2 *  ts2 - ts2) + ts2);
								break;
							}
							case 3:  sample += otStr * noiseBuf[(int)(tn * 32.0f) & 31]; break;
							case 4:  sample += otStr * (MathF.Abs(1.0f - tn * 2.0f) - 1.0f); break;
							case 5:
								sample += otStr * (Akwf_granular_0044[(int)(tn * 256f) & 255] / 32768f - 1f);
								break;
							case 6:
							{
								float tv2 = MathF.Tan(MathF.PI * tn);
								sample += otStr * ((tv2 < 4.0f && tv2 > -4.0f) ? tv2 : (tv2 > 0.0f ? 4.0f : -4.0f));
								break;
							}
							case 7:
							{
								float wp2  = tn > 0.5f ? (tn - 1.0f) * Mathf.Tau : tn * Mathf.Tau;
								float wts2 = wp2 < 0.0f
									? 1.27323954f * wp2 + 0.405284735f * wp2 * wp2
									: 1.27323954f * wp2 - 0.405284735f * wp2 * wp2;
								sample += otStr * (wts2 < 0.0f
									? 0.225f * (wts2 * -wts2 - wts2) + wts2
									: 0.225f * (wts2 *  wts2 - wts2) + wts2);
								break;
							}
							case 8:  sample += otStr * (MathF.Abs(1.0f - tn * tn * 2.0f) - 1.0f); break;
							case 9:  sample += otStr * oneBitVal; break;
							case 10:
								sample += otStr * (Akwf_fmsynth_0012[(int)(tn * 256f) & 255] / 32768f - 1f);
								break;
							case 11:
								sample += otStr * (Akwf_hvoice_0012[(int)(tn * 256f) & 255] / 32768f - 1f);
								break;
						}
						otStr *= (1.0f - otFalloff);
					}
				}

				// ── LP + HP filter ────────────────────────────────────────────
				if (useFilters)
				{
					float lpOld = lpPos;
					lpCutoff *= lpDcut;
					if      (lpCutoff < 0.0f) lpCutoff = 0.0f;
					else if (lpCutoff > 0.1f) lpCutoff = 0.1f;
					if (lpOn)
					{
						lpDpos += (sample - lpPos) * lpCutoff;
						lpDpos *= lpDamp;
					}
					else
					{
						lpPos  = sample;
						lpDpos = 0.0f;
					}
					lpPos += lpDpos;
					hpPos += lpPos - lpOld;
					hpPos *= 1.0f - hpCutoff;
					sample = hpPos;
				}

				// ── Flanger ───────────────────────────────────────────────────
				if (useFlanger)
				{
					flangerBuf[flangerPos & 1023] = sample;
					sample    += flangerBuf[(flangerPos - flangerInt + 1024) & 1023];
					flangerPos = (flangerPos + 1) & 1023;
				}

				superSample += sample;
			}

			// ── Clamp super-sample ────────────────────────────────────────────
			if      (superSample >  8.0f) superSample =  8.0f;
			else if (superSample < -8.0f) superSample = -8.0f;

			// ── Bit crush ─────────────────────────────────────────────────────
			bcPhase += bcFreq;
			if (bcPhase > 1.0f)
			{
				bcPhase = 0.0f;
				bcLast  = superSample;
			}
			float bcMult = Mathf.Lerp(1.0f, 50.0f * bcFreq, MathF.Sqrt(bcFreq));
			bcFreq += bcMult * bcSweep;
			if      (bcFreq < 0.00001f) bcFreq = 0.00001f;
			else if (bcFreq > 1.0f)     bcFreq = 1.0f;
			superSample = bcLast;

			// ── Volume
			// Normaliser is 1/SuperSampleCount (0.125 at 8x, 0.25 at 4x).
			// Matches the JS * 0.125 which hard-coded its 8x inner loop count.
			superSample = masterVol * envVol * superSample * (1.0f / SuperSampleCount);

			// ── Compressor ────────────────────────────────────────────────────
			if (useCompr)
			{
				if      (superSample > 0.0f) superSample =  MathF.Pow( superSample, compress);
				else if (superSample < 0.0f) superSample = -MathF.Pow(-superSample, compress);
			}

			// ── Early-out when frequency has hit its floor ────────────────────
			if (muted)
			{
				usedBytes = i * 2;
				break;
			}

			if (superSample > 0.002f || superSample < -0.002f)
				lastNonzero = i;

			int ival = (int)(superSample * 32767.0f);
			if      (ival >  32767) ival =  32767;
			else if (ival < -32768) ival = -32768;
			sampleSpan[i] = (short)ival;
		}

		// ── Trim silent tail ──────────────────────────────────────────────────
		if (lastNonzero >= 0 && lastNonzero < fullLen - 1)
			usedBytes = Math.Max(lastNonzero + 1, 10) * 2;

		return (bytes, usedBytes);
	}

	// ─────────────────────────────────────────────────────────────────────────
	//  AKWF WAVETABLES
	//
	//  Single-cycle waveforms from the Adventure Kid Waveforms (AKWF) library.
	//  https://www.adventurekid.se/akrt/waveforms/adventure-kid-waveforms/
	//  Public domain, CC0 1.0 Universal.
	//
	//  256 samples each, stored as ushort (0..65535 unsigned).
	//  Lookup: table[(int)(norm * 256f) & 255] / 32768f - 1f  →  [-1, 1]
	//  This exactly replicates the JS: AKWF.name[sample_index] / 32768 - 1
	//
	//  Used by:
	//    waveType 5  (Rasp)   → Akwf_granular_0044
	//    waveType 10 (FMSyn)  → Akwf_fmsynth_0012
	//    waveType 11 (Voice)  → Akwf_hvoice_0012
	// ─────────────────────────────────────────────────────────────────────────

	private static readonly ushort[] Akwf_granular_0044 = {
		32869, 33554, 33950, 34774, 35134, 36047, 36319, 37297, 37454, 38494, 38511, 39617, 39443, 40664, 40161, 41814,
		38882, 23368, 22518, 21974, 20997, 20545, 19523, 19169, 18210, 17982, 17163, 17128, 16552, 16803, 16594, 17281,
		17607, 18928, 20002, 22162, 24166, 27270, 30129, 33900, 37194, 41086, 44210, 47679, 50274, 53080, 55123, 57263,
		58843, 60380, 61646, 62635, 63750, 64193, 65294, 65000, 65535, 64171, 65114, 62655, 64487, 59956, 65114, 36210,
		   212,  3832,    99,  1558,     1,   510,     0,   197,   120,   547,  1094,  1697,  2901,  3914,  5892,  7586,
		10533, 13157, 17216, 20988, 26107, 30361, 35515, 39386, 43777, 46670, 49891, 51621, 53703, 54463, 55644, 55730,
		56241, 55895, 55900, 55320, 54914, 54268, 53486, 52949, 51761, 51561, 49784, 50399, 47306, 51139, 28999, 14730,
		19959, 17550, 20023, 18982, 20690, 20318, 21655, 21737, 22859, 23286, 24286, 24994, 25914, 26840, 27701, 28756,
		29549, 30623, 31268, 32196, 32566, 33184, 33197, 33422, 33100, 32970, 32677, 32843, 32704, 32820, 32726, 32801,
		32745, 32785, 32759, 32771, 32771, 32760, 32779, 32753, 32784, 32751, 32787, 32749, 32786, 32751, 32785, 32753,
		32782, 32756, 32779, 32759, 32775, 32762, 32773, 32765, 32771, 32768, 32768, 32769, 32767, 32769, 32766, 32770,
		32766, 32769, 32767, 32770, 32767, 32769, 32767, 32770, 32768, 32768, 32768, 32768, 32768, 32768, 32768, 32768,
		32768, 32767, 32767, 32768, 32767, 32768, 32767, 32768, 32769, 32768, 32768, 32768, 32768, 32768, 32768, 32768,
		32767, 32768, 32768, 32768, 32769, 32768, 32768, 32768, 32767, 32768, 32768, 32769, 32768, 32768, 32767, 32769,
		32767, 32769, 32768, 32769, 32767, 32768, 32767, 32768, 32768, 32768, 32768, 32767, 32770, 32767, 32770, 32766,
		32771, 32765, 32772, 32762, 32775, 32757, 32786, 32653, 32303, 32073, 32011, 32104, 32434, 32756, 32768, 32767
	};

	private static readonly ushort[] Akwf_fmsynth_0012 = {
		33063, 33949, 34766, 35596, 36388, 37173, 37929, 38666, 39379, 40067, 40731, 41364, 41976, 42552, 43106, 43625,
		44121, 44580, 45016, 45417, 45794, 46139, 46456, 46745, 47012, 47248, 47464, 47656, 47829, 47980, 48113, 48229,
		48329, 48416, 48490, 48551, 48601, 48643, 48676, 48703, 48723, 48736, 48745, 48748, 48747, 48741, 48728, 48714,
		48693, 48667, 48635, 48595, 48550, 48497, 48436, 48364, 48284, 48193, 48090, 47974, 47846, 47706, 47550, 47380,
		47192, 46991, 46774, 46540, 46289, 46023, 45740, 45441, 45125, 44794, 44446, 44084, 43708, 43316, 42915, 42499,
		42073, 41634, 41187, 40727, 40263, 39791, 39311, 38826, 38337, 37843, 37348, 36850, 36350, 35850, 35350, 34852,
		34356, 33862, 33369, 32882, 32401, 31923, 31451, 30983, 30524, 30072, 29626, 29187, 28759, 28338, 27928, 27527,
		27135, 26754, 26385, 26024, 25678, 25343, 25020, 24708, 24412, 24128, 23858, 23602, 23360, 23134, 22922, 22727,
		22547, 22383, 22235, 22105, 21991, 21894, 21816, 21755, 21711, 21687, 21680, 21693, 21724, 21775, 21845, 21934,
		22044, 22172, 22320, 22487, 22677, 22885, 23113, 23363, 23631, 23921, 24229, 24558, 24908, 25279, 25671, 26081,
		26514, 26965, 27437, 27932, 28443, 28979, 29533, 30108, 30703, 31318, 31954, 32607, 33281, 33975, 34687, 35416,
		36163, 36925, 37703, 38490, 39289, 40096, 40909, 41719, 42527, 43324, 44108, 44867, 45598, 46286, 46925, 47500,
		47996, 48401, 48694, 48858, 48869, 48707, 48340, 47746, 46886, 45734, 44239, 42380, 40091, 37352, 34077, 30264,
		25772, 21005, 16784, 13147, 10049,  7453,  5312,  3592,  2252,  1258,   572,   166,     4,    62,   308,   722,
		 1277,  1954,  2735,  3599,  4533,  5522,  6558,  7622,  8712,  9817, 10931, 12049, 13166, 14275, 15381, 16475,
		17558, 18628, 19685, 20730, 21760, 22777, 23780, 24757, 25723, 26697, 27638, 28588, 29498, 30430, 31300, 32236
	};

	private static readonly ushort[] Akwf_hvoice_0012 = {
		33078, 34077, 35044, 36007, 36938, 37805, 38590, 39410, 40186, 40979, 41828, 42751, 43765, 44750, 45625, 46506,
		47377, 48459, 49580, 50412, 51254, 52132, 53054, 53969, 55064, 56224, 57157, 57762, 58474, 59326, 60025, 60421,
		60707, 60933, 61192, 61199, 60011, 57771, 55825, 55237, 55020, 53932, 51409, 48089, 45399, 44422, 44106, 42490,
		39350, 35232, 30729, 27122, 25230, 23798, 21402, 18034, 14910, 12701, 11362, 10543,  9717,  8561,  7008,  4596,
		 1765,   131,   201,  1146,  2023,  2735,  3299,  3911,  5049,  7131,  9717, 11930, 13324, 14032, 14722, 16044,
		18235, 21043, 24261, 27245, 29408, 31047, 33083, 35737, 38158, 39841, 40886, 41556, 42213, 43245, 44552, 45917,
		47119, 47870, 48264, 48770, 49539, 49925, 49668, 49229, 48873, 48432, 47913, 47384, 46902, 46605, 46302, 45760,
		45142, 44704, 44318, 43802, 43332, 43042, 42636, 41996, 41337, 40780, 40348, 40072, 39783, 39377, 39035, 38729,
		38329, 37958, 37837, 37831, 37639, 37223, 36573, 35566, 34312, 33093, 32117, 31428, 30844, 30079, 29059, 27979,
		27098, 26276, 25428, 24454, 23049, 21274, 19381, 17785, 16557, 15675, 15000, 14446, 13983, 13647, 13422, 13168,
		12982, 12753, 12429, 12068, 11998, 12294, 12943, 13955, 15251, 16750, 18381, 20097, 21804, 23476, 25102, 26674,
		28171, 29696, 31260, 32930, 34804, 36952, 39192, 41282, 43127, 44699, 46099, 47372, 48514, 49476, 50175, 50618,
		50888, 51099, 51305, 51404, 51383, 51221, 50812, 50133, 49166, 47971, 46660, 45347, 44055, 42645, 40991, 39107,
		37176, 35376, 33764, 32251, 30646, 28956, 27272, 25659, 24192, 22866, 21633, 20368, 19107, 17971, 16966, 16123,
		15408, 14840, 14468, 14309, 14374, 14559, 14792, 14960, 15096, 15298, 15643, 16099, 16589, 17068, 17606, 18341,
		19312, 20471, 21661, 22740, 23624, 24392, 25151, 25945, 26715, 27439, 28051, 28700, 29403, 30342, 31272, 32180
	};

	// ─────────────────────────────────────────────────────────────────────────
	//  PARAM SNAPSHOT
	// ─────────────────────────────────────────────────────────────────────────

	private readonly struct BfxrParamSnapshot
	{
		public readonly float MasterVolume;
		public readonly float AttackTime;
		public readonly float SustainTime;
		public readonly float SustainPunch;
		public readonly float DecayTime;
		public readonly float CompressionAmount;
		public readonly float FrequencyStart;
		public readonly float MinFrequencyRelative;
		public readonly float VibratoDepth;
		public readonly float VibratoSpeed;
		public readonly float PitchJumpRepeatSpeed;
		public readonly float PitchJumpOnsetPercent;
		public readonly float PitchJumpOnset2Percent;
		public readonly float Overtones;
		public readonly float OvertoneFalloff;
		public readonly float SquareDuty;
		public readonly float RepeatSpeed;
		public readonly float LpFilterCutoff;
		public readonly float LpFilterResonance;
		public readonly float HpFilterCutoff;
		public readonly float BitCrush;
		public readonly float FrequencySlide;
		public readonly float FrequencyAcceleration;
		public readonly float PitchJumpAmount;
		public readonly float PitchJump2Amount;
		public readonly float DutySweep;
		public readonly float FlangerOffset;
		public readonly float FlangerSweep;
		public readonly float LpFilterCutoffSweep;
		public readonly float HpFilterCutoffSweep;
		public readonly float BitCrushSweep;
		public readonly int   WaveType;

		public BfxrParamSnapshot(Godot.Collections.Dictionary p)
		{
			float at = (float)p["attackTime"];
			float st = (float)p["sustainTime"];
			float dt = (float)p["decayTime"];

			if (st < 0.01f) st = 0.01f;
			const float MinLen = 0.18f;
			float totalT = at + st + dt;
			if (totalT < MinLen)
			{
				float m = MinLen / totalT;
				at *= m; st *= m; dt *= m;
			}

			AttackTime  = at;
			SustainTime = st;
			DecayTime   = dt;

			MasterVolume            = (float)p["masterVolume"];
			WaveType                = (int)p["waveType"];
			SustainPunch            = (float)p["sustainPunch"];
			CompressionAmount       = (float)p["compressionAmount"];
			FrequencyStart          = (float)p["frequency_start"];
			FrequencySlide          = (float)p["frequency_slide"];
			FrequencyAcceleration   = (float)p["frequency_acceleration"];
			MinFrequencyRelative    = (float)p["min_frequency_relative_to_starting_frequency"];
			VibratoDepth            = (float)p["vibratoDepth"];
			VibratoSpeed            = (float)p["vibratoSpeed"];
			PitchJumpRepeatSpeed    = (float)p["pitch_jump_repeat_speed"];
			PitchJumpAmount         = (float)p["pitch_jump_amount"];
			PitchJumpOnsetPercent   = (float)p["pitch_jump_onset_percent"];
			PitchJump2Amount        = (float)p["pitch_jump_2_amount"];
			PitchJumpOnset2Percent  = (float)p["pitch_jump_onset2_percent"];
			Overtones               = (float)p["overtones"];
			OvertoneFalloff         = (float)p["overtoneFalloff"];
			SquareDuty              = (float)p["squareDuty"];
			DutySweep               = (float)p["dutySweep"];
			RepeatSpeed             = (float)p["repeatSpeed"];
			FlangerOffset           = (float)p["flangerOffset"];
			FlangerSweep            = (float)p["flangerSweep"];
			LpFilterCutoff          = (float)p["lpFilterCutoff"];
			LpFilterCutoffSweep     = (float)p["lpFilterCutoffSweep"];
			LpFilterResonance       = (float)p["lpFilterResonance"];
			HpFilterCutoff          = (float)p["hpFilterCutoff"];
			HpFilterCutoffSweep     = (float)p["hpFilterCutoffSweep"];
			BitCrush                = (float)p["bitCrush"];
			BitCrushSweep           = (float)p["bitCrushSweep"];
		}
	}

	// ─────────────────────────────────────────────────────────────────────────
	//  PARAM HELPERS
	// ─────────────────────────────────────────────────────────────────────────

	private static Godot.Collections.Dictionary Defaults() => new()
	{
		["masterVolume"] = 0.5f,  ["waveType"] = 0,
		["attackTime"]   = 0.0f,  ["sustainTime"] = 0.3f,
		["sustainPunch"] = 0.0f,  ["decayTime"] = 0.4f,
		["compressionAmount"] = 0.0f,
		["frequency_start"]        = 0.3f,
		["frequency_slide"]        = 0.0f,
		["frequency_acceleration"] = 0.0f,
		["min_frequency_relative_to_starting_frequency"] = 0.0f,
		["vibratoDepth"] = 0.0f, ["vibratoSpeed"] = 0.0f,
		["pitch_jump_repeat_speed"]  = 0.0f,
		["pitch_jump_amount"]        = 0.0f, ["pitch_jump_onset_percent"]  = 0.0f,
		["pitch_jump_2_amount"]      = 0.0f, ["pitch_jump_onset2_percent"] = 0.0f,
		["overtones"] = 0.0f, ["overtoneFalloff"] = 0.0f,
		["squareDuty"] = 0.0f, ["dutySweep"] = 0.0f,
		["repeatSpeed"] = 0.0f,
		["flangerOffset"] = 0.0f, ["flangerSweep"] = 0.0f,
		["lpFilterCutoff"] = 1.0f, ["lpFilterCutoffSweep"] = 0.0f, ["lpFilterResonance"] = 0.0f,
		["hpFilterCutoff"] = 0.0f, ["hpFilterCutoffSweep"] = 0.0f,
		["bitCrush"] = 0.0f, ["bitCrushSweep"] = 0.0f,
	};

	private static void FillDefaults(Godot.Collections.Dictionary p)
	{
		var d = Defaults();
		foreach (var key in d.Keys)
			if (!p.ContainsKey(key)) p[key] = d[key];
	}

	private static void RandomizeParams(Godot.Collections.Dictionary p)
	{
		var powers = new System.Collections.Generic.Dictionary<string, int>
		{
			["attackTime"] = 4, ["sustainTime"] = 2, ["sustainPunch"] = 2,
			["overtones"] = 3, ["overtoneFalloff"] = 2, ["vibratoDepth"] = 3,
			["dutySweep"] = 3, ["flangerOffset"] = 3, ["flangerSweep"] = 3,
			["lpFilterCutoff"] = 3, ["lpFilterCutoffSweep"] = 3,
			["hpFilterCutoff"] = 5, ["hpFilterCutoffSweep"] = 5,
			["bitCrush"] = 4, ["bitCrushSweep"] = 5,
			["frequency_slide"] = 4, ["frequency_acceleration"] = 7, ["frequency_start"] = 4,
		};
		var ranges = new System.Collections.Generic.Dictionary<string, (float mn, float mx, float dv)>
		{
			["masterVolume"]   = (0.0f,  1.0f,  0.5f),
			["attackTime"]     = (0.0f,  1.0f,  0.0f),
			["sustainTime"]    = (0.0f,  1.0f,  0.3f),
			["sustainPunch"]   = (0.0f,  1.0f,  0.0f),
			["decayTime"]      = (0.03f, 1.0f,  0.4f),
			["compressionAmount"] = (0.0f, 1.0f, 0.0f),
			["frequency_start"] = (0.0f, 1.0f,  0.3f),
			["frequency_slide"] = (-0.5f, 0.5f, 0.0f),
			["frequency_acceleration"] = (-1.0f, 1.0f, 0.0f),
			["min_frequency_relative_to_starting_frequency"] = (0.0f, 0.99f, 0.0f),
			["vibratoDepth"]   = (0.0f,  1.0f,  0.0f),
			["vibratoSpeed"]   = (0.0f,  1.0f,  0.0f),
			["pitch_jump_repeat_speed"] = (0.0f, 1.0f, 0.0f),
			["pitch_jump_amount"]       = (-1.0f, 1.0f, 0.0f),
			["pitch_jump_onset_percent"]  = (0.0f, 1.0f, 0.0f),
			["pitch_jump_2_amount"]       = (-1.0f, 1.0f, 0.0f),
			["pitch_jump_onset2_percent"] = (0.0f, 1.0f, 0.0f),
			["overtones"]      = (0.0f,  1.0f,  0.0f),
			["overtoneFalloff"] = (0.0f, 1.0f,  0.0f),
			["squareDuty"]     = (0.0f,  0.99f, 0.0f),
			["dutySweep"]      = (-1.0f, 1.0f,  0.0f),
			["repeatSpeed"]    = (0.0f,  1.0f,  0.0f),
			["flangerOffset"]  = (-1.0f, 1.0f,  0.0f),
			["flangerSweep"]   = (-1.0f, 1.0f,  0.0f),
			["lpFilterCutoff"] = (0.01f, 1.0f,  1.0f),
			["lpFilterCutoffSweep"] = (-1.0f, 1.0f, 0.0f),
			["lpFilterResonance"] = (0.0f, 1.0f, 0.0f),
			["hpFilterCutoff"] = (0.0f,  1.0f,  0.0f),
			["hpFilterCutoffSweep"] = (-1.0f, 1.0f, 0.0f),
			["bitCrush"]       = (0.0f,  1.0f,  0.0f),
			["bitCrushSweep"]  = (-1.0f, 1.0f,  0.0f),
		};
		foreach (var (param, range) in ranges)
		{
			float r = Randf();
			if (powers.TryGetValue(param, out int exp))
				r = MathF.Pow(r, exp);
			bool above = Randf() < 0.5f;
			if (range.mn == range.dv) above = true;
			if (range.mx == range.dv) above = false;
			p[param] = above
				? range.dv + (range.mx - range.dv) * r
				: range.dv - (range.dv - range.mn) * r;
		}
		p["waveType"]   = RandN(11);
		if (Randf() < 0.5f) p["repeatSpeed"] = 0.0f;
		p["min_frequency_relative_to_starting_frequency"] = 0.0f;
		p["compressionAmount"] = 0.0f;
	}

	// ─────────────────────────────────────────────────────────────────────────
	//  RANDOM HELPERS
	// ─────────────────────────────────────────────────────────────────────────

	private static float Randf()                        => Random.Shared.NextSingle();
	private static float RandF(float min, float max)    => min + Random.Shared.NextSingle() * (max - min);
	private static int   RandI(int min, int max)        => min + (int)((uint)Random.Shared.Next() % (uint)(max - min + 1));
	private static int   RandN(int n)                   => (int)((uint)Random.Shared.Next() % (uint)n);
	private static float RandNoise()                    => Random.Shared.NextSingle() * 2.0f - 1.0f;
}
