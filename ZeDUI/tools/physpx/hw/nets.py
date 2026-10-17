"""The two makeshift sets' circuits, as the boards must wire them. One source of truth: the schematic drawings for the
director, the hand-wired boards and the checker all read these.

A part is  name -> (kind, value, pins);  a net is  name -> ["PART.pin", ...].  Every pin of every part sits on exactly
one net, or is listed in `open` (left unconnected on purpose, as the source circuit leaves it).

RADIO  (the makeshift radio, 88-108 megahertz)
  The receiver is the Philips TDA7000 test circuit (data sheet, May 1992, Fig. 4) with the test generator replaced by
  an antenna lead, as the data sheet's own board does (Fig. 6, "IN"). The muting switch and its 10k are left out: the
  switch's "enabled" position is open, so leaving both out wires the same circuit. Cp and Cs (the oscillator's fixed
  capacitors) have no values in the data sheet; 33p and 100p put the tuning across 88-108 with a 2-20p tuning section.
  The amplifier is the National LM386 data sheet's "Amplifier with Gain = 20, Minimum Parts". One capacitor that is in
  neither drawing joins them: 220n from the TDA7000's audio output to the top of the volume control (the output sits
  at a couple of volts; the volume control must not carry it).
  The display-and-keys board is salvaged and bolted on; its ribbon cable takes power and ground only.

TWOWAY  (the makeshift two-way)
  Talking Electronics, "27MHz Links" (Colin Mitchell), Fig. 24 "A 4-Transistor Walkie Talkie": one transistor
  receives (super-regenerative) and transmits (crystal-locked), three amplify; the speaker is the microphone while
  talking; a four-pole talk/listen switch changes it over. The text calls the emitter resistor 330R, the drawing 390R:
  the drawing wins.
  The display-and-keys board is salvaged and bolted on, as on the radio; its ribbon cable takes the switched supply
  (after the power switch) and ground only.
"""

# ------------------------------------------------------------------------------------------------ the radio
RADIO_PARTS = {
    "U1": ("ic", "TDA7000", [str(i) for i in range(1, 19)]),
    "C1": ("cap", "150n", ["1", "2"]), "C2": ("cap", "1n8", ["1", "2"]), "C3": ("cap", "22n", ["1", "2"]),
    "C4": ("cap", "10n", ["1", "2"]), "C5": ("cap", "10n", ["1", "2"]), "C7": ("cap", "3n3", ["1", "2"]),
    "C8": ("cap", "180p", ["1", "2"]), "C10": ("cap", "330p", ["1", "2"]), "C11": ("cap", "3n3", ["1", "2"]),
    "C12": ("cap", "150p", ["1", "2"]), "C13": ("cap", "220p", ["1", "2"]), "C14": ("cap", "220p", ["1", "2"]),
    "C15": ("cap", "100n", ["1", "2"]), "C17": ("cap", "330p", ["1", "2"]), "C18": ("cap", "220p", ["1", "2"]),
    "CP": ("cap", "33p", ["1", "2"]), "CS": ("cap", "100p", ["1", "2"]),
    "CV": ("varcap", "2-20p", ["1", "2"]),
    "L1": ("coil", "56nH", ["1", "2"]),
    "RL": ("res", "22k", ["1", "2"]),
    "CC": ("cap", "220n", ["1", "2"]),
    "VR1": ("pot", "10k", ["1", "2", "3"]),            # 1 top, 2 wiper, 3 bottom
    "U2": ("ic", "LM386", [str(i) for i in range(1, 9)]),
    "C20": ("ecap", "250u", ["+", "-"]), "C21": ("cap", "0.05u", ["1", "2"]), "R20": ("res", "10R", ["1", "2"]),
    "SPK": ("spk", "8R", ["1", "2"]),
    "SW1": ("switch", "power", ["1", "2"]),
    "BT1": ("batt", "4.5V", ["+", "-"]),
    "ANT": ("ant", "", ["1"]),
    "J1": ("ribbon", "display board", ["VP", "GND"]),
}

RADIO_NETS = {
    "VP": ["U1.5", "C1.2", "C3.2", "C4.2", "C5.1", "L1.1", "CP.1", "CV.1", "C8.2", "C11.2", "C12.2", "C15.2", "C17.2",
           "C18.2", "SW1.2", "U2.6", "J1.VP"],
    "GND": ["U1.16", "C2.2", "RL.2", "C5.2", "C14.2", "VR1.3", "U2.2", "U2.4", "R20.2", "SPK.2", "BT1.-", "J1.GND"],
    "P1": ["U1.1", "C1.1"],
    "AF": ["U1.2", "C2.1", "RL.1", "CC.1"],
    "P3": ["U1.3", "C3.1"],
    "P4": ["U1.4", "C4.1"],
    "OSC": ["U1.6", "L1.2", "CP.2", "CS.2"],
    "CVS": ["CV.2", "CS.1"],
    "P7": ["U1.7", "C7.1"],
    "P8": ["U1.8", "C8.1"],
    "P9": ["U1.9", "C7.2"],
    "P10": ["U1.10", "C10.2"],
    "P11": ["U1.11", "C10.1", "C11.1"],
    "P12": ["U1.12", "C12.1"],
    "P13": ["U1.13", "C13.2"],
    "ANT": ["ANT.1", "C13.1"],
    "P14": ["U1.14", "C14.1"],
    "P15": ["U1.15", "C15.1"],
    "P17": ["U1.17", "C17.1"],
    "P18": ["U1.18", "C18.1"],
    "POT": ["CC.2", "VR1.1"],
    "IN": ["VR1.2", "U2.3"],
    "OUT": ["U2.5", "C20.+", "C21.1"],
    "ZOB": ["C21.2", "R20.1"],
    "SPKP": ["C20.-", "SPK.1"],
    "BATT": ["BT1.+", "SW1.1"],
}
RADIO_OPEN = ["U2.1", "U2.7", "U2.8"]          # gain and bypass pins: open for a gain of 20, as the data sheet draws it

# ------------------------------------------------------------------------------------------------ the two-way
TWOWAY_PARTS = {
    "ANT": ("ant", "", ["1"]),
    "LA": ("coil", "loading", ["1", "2"]),
    "T1": ("rfxfmr", "9t:2t", ["P1", "P2", "S1", "S2"]),       # 9 turns P1-P2, 2 turns S1-S2, a tuning slug
    "C1": ("cap", "15p", ["1", "2"]), "C2": ("cap", "10n", ["1", "2"]),
    "R1": ("res", "33k", ["1", "2"]), "R2": ("res", "15k", ["1", "2"]),
    "C3": ("cap", "39n", ["1", "2"]),
    "Q1": ("npn", "BC547", ["C", "B", "E"]),
    "C4": ("cap", "33p", ["1", "2"]),
    "R3": ("res", "56R", ["1", "2"]), "C5": ("cap", "82p", ["1", "2"]),
    "R4": ("res", "390R", ["1", "2"]), "C6": ("cap", "10n", ["1", "2"]),
    "X1": ("xtal", "27MHz", ["1", "2"]),
    "SW1A": ("spdt", "talk/listen A", ["C", "T", "R"]),
    "SW1B": ("spdt", "talk/listen B", ["C", "T", "R"]),
    "SW1C": ("spdt", "talk/listen C", ["C", "T", "R"]),
    "SW1D": ("spdt", "talk/listen D", ["C", "T", "R"]),
    "C7": ("cap", "4n7", ["1", "2"]), "C8": ("cap", "22n", ["1", "2"]),
    "C9": ("ecap", "0.47u", ["+", "-"]),
    "R5": ("res", "4k7", ["1", "2"]),
    "VR1": ("pot", "10k", ["1", "2", "3"]),
    "C10": ("cap", "39n", ["1", "2"]),
    "R6": ("res", "3k9", ["1", "2"]), "R7": ("res", "1M", ["1", "2"]), "C11": ("cap", "220p", ["1", "2"]),
    "C12": ("cap", "4n7", ["1", "2"]),
    "Q2": ("npn", "BC547", ["C", "B", "E"]),
    "R8": ("res", "5k6", ["1", "2"]),
    "C13": ("ecap", "100u", ["+", "-"]),
    "R9": ("res", "220R", ["1", "2"]),
    "Q3": ("npn", "BC547", ["C", "B", "E"]),
    "C14": ("cap", "22n", ["1", "2"]),
    "Q4": ("npn", "BC338", ["C", "B", "E"]),
    "R10": ("res", "100R", ["1", "2"]), "C15": ("ecap", "33u", ["+", "-"]),
    "T2": ("afxfmr", "speaker transformer", ["P1", "P2", "S1", "S2"]),
    "SPK": ("spk", "8R", ["1", "2"]),
    "SW2": ("switch", "on/off", ["1", "2"]),
    "BT1": ("batt", "9V", ["+", "-"]),
    "J1": ("ribbon", "display board", ["VP", "GND"]),
}

TWOWAY_NETS = {
    "GND": ["R2.2", "X1.2", "SW1B.R", "SW1C.C", "R4.2", "C6.2", "T1.S2", "C1.2", "C2.2", "C7.2", "C8.2", "VR1.3",
            "C12.2", "Q2.E", "C13.-", "C14.2", "C15.-", "R10.2", "T2.S2", "SPK.2", "BT1.-", "J1.GND"],
    "ANT": ["ANT.1", "LA.1"],
    "ANT2": ["LA.2", "T1.S1", "C1.1"],
    "SUP": ["R1.1", "T1.P1", "C2.1", "SW1A.C"],
    "COLL": ["T1.P2", "Q1.C", "C4.1"],
    "BASE": ["Q1.B", "R1.2", "R2.1", "C3.1"],
    "B39": ["C3.2", "SW1B.T", "SW1C.R"],
    "XT": ["SW1B.C", "X1.1"],
    "EMIT": ["Q1.E", "C4.2", "R3.1", "C5.1"],
    "ETAP": ["R3.2", "C5.2", "R4.1", "C6.1", "SW1C.T"],
    "CN": ["SW1A.T", "C8.1", "Q3.C", "Q4.C", "T2.P2"],
    "RLINE": ["SW1A.R", "C7.1", "C9.+", "R5.1"],
    "POT": ["C9.-", "VR1.1"],
    "WIPER": ["VR1.2", "C10.1", "SW1D.T"],
    "B2IN": ["C10.2", "R6.1"],
    "B2": ["R6.2", "R7.2", "C11.2", "Q2.B", "C12.1"],
    "C2N": ["Q2.C", "R8.2", "R7.1", "C11.1", "Q3.B", "C14.1"],
    "V2": ["R5.2", "R8.1", "C13.+", "R9.1"],
    "VPLUS": ["R9.2", "T2.P1", "SW2.1", "J1.VP"],
    "BATT": ["SW2.2", "BT1.+"],
    "E3": ["Q3.E", "Q4.B"],
    "E4": ["Q4.E", "R10.1", "C15.+"],
    "SEC": ["T2.S1", "SW1D.R"],
    "SPKN": ["SW1D.C", "SPK.1"],
}
TWOWAY_OPEN = []


def check(parts, nets, open_=()):
    """every pin on exactly one net (or open), every net's pins real"""
    seen, errs = {}, []
    for n, pins in nets.items():
        if len(pins) < 2: errs.append(f"net {n} has {len(pins)} pin")
        for pn in pins:
            part, _, pin = pn.partition(".")
            if part not in parts: errs.append(f"{n}: no part {part}"); continue
            if pin not in parts[part][2]: errs.append(f"{n}: {part} has no pin {pin}")
            if pn in seen: errs.append(f"{pn} on {seen[pn]} and {n}")
            seen[pn] = n
    for o in open_:
        if o in seen: errs.append(f"{o} is open and on {seen[o]}")
        seen[o] = "(open)"
    for part, (_, _, pins) in parts.items():
        for pin in pins:
            if f"{part}.{pin}" not in seen: errs.append(f"{part}.{pin} on no net")
    return errs


def net_of(nets):
    return {pn: n for n, pins in nets.items() for pn in pins}


if __name__ == "__main__":
    for name, parts, nets, open_ in (("radio", RADIO_PARTS, RADIO_NETS, RADIO_OPEN), ("two-way", TWOWAY_PARTS, TWOWAY_NETS, TWOWAY_OPEN)):
        e = check(parts, nets, open_)
        print(name, len(parts), "parts", len(nets), "nets", sum(len(v) for v in nets.values()), "joints", "OK" if not e else e)
