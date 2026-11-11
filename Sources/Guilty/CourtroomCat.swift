import SwiftUI

/// A vector mascot, drawn locally so it stays sharp at every window size.
struct CourtroomCat: View {
    enum Mood { case idle, watching, judging, sleeping, celebrating, calling }
    var mood: Mood = .watching
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var label: String {
        switch mood {
        case .idle: return "Judge Whiskers is relaxed and ready."
        case .calling: return "Judge Whiskers is calling you back from your break."
        case .watching: return "Judge Whiskers is keeping an eye on your focus session."
        case .judging: return "Judge Whiskers gives you THE LOOK."
        case .sleeping: return "Judge Whiskers is sleeping during recess."
        case .celebrating: return "Judge Whiskers celebrates your completed session."
        }
    }
    var body: some View {
        TimelineView(.animation(minimumInterval: reduceMotion ? 1 : 1.0 / 12)) { context in
            let judging = mood == .judging
            let sleeping = mood == .sleeping && !judging
            let celebrating = mood == .celebrating && !judging
            let seconds = context.date.timeIntervalSinceReferenceDate
            let bob = reduceMotion ? 0 : sin(seconds * (sleeping ? 1.5 : 2)) * (celebrating ? 3 : 1)
            let blink = !reduceMotion && seconds.truncatingRemainder(dividingBy: 5.5) < 0.16
            Canvas { context, size in
                context.scaleBy(x: size.width / 220, y: size.height / 184)
                let fur = Color(red: 0.72, green: 0.61, blue: 0.48)
                let dark = Color(red: 0.12, green: 0.16, blue: 0.15)
                let cream = Color(red: 0.96, green: 0.93, blue: 0.84)
                let lime = Color(red: 0.77, green: 0.95, blue: 0.39)
                func ellipse(_ x: Double, _ y: Double, _ w: Double, _ h: Double, _ color: Color) {
                    context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: w, height: h)), with: .color(color))
                }
                func shape(_ points: [CGPoint], _ color: Color) {
                    var path = Path(); path.addLines(points); path.closeSubpath()
                    context.fill(path, with: .color(color))
                }
                func line(_ points: [CGPoint], _ color: Color, _ width: Double = 3) {
                    var path = Path(); path.addLines(points)
                    context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
                }
                // The bench and robe ground the little judge in the sidebar.
                ellipse(37, 162, 148, 15, .black.opacity(0.18))
                var robe = Path()
                robe.move(to: CGPoint(x: 62, y: 156))
                robe.addQuadCurve(to: CGPoint(x: 158, y: 156), control: CGPoint(x: 110, y: 28))
                robe.closeSubpath()
                context.fill(robe, with: .color(Color(red: 0.26, green: 0.29, blue: 0.28)))
                shape([CGPoint(x: 94, y: 116), CGPoint(x: 126, y: 116), CGPoint(x: 119, y: 146), CGPoint(x: 101, y: 146)], cream)
                line([CGPoint(x: 110, y: 122), CGPoint(x: 110, y: 145)], dark.opacity(0.4), 1)
                let y = bob
                // Ears peek through an absurdly serious powdered wig.
                shape([CGPoint(x: 60, y: 65+y), CGPoint(x: 60, y: 16+y), CGPoint(x: 91, y: 42+y)], fur)
                shape([CGPoint(x: 131, y: 42+y), CGPoint(x: 162, y: 16+y), CGPoint(x: 160, y: 67+y)], fur)
                shape([CGPoint(x: 66, y: 45+y), CGPoint(x: 66, y: 27+y), CGPoint(x: 81, y: 43+y)], Color(red: 0.77, green: 0.47, blue: 0.46))
                shape([CGPoint(x: 141, y: 43+y), CGPoint(x: 155, y: 27+y), CGPoint(x: 155, y: 47+y)], Color(red: 0.77, green: 0.47, blue: 0.46))
                ellipse(57, 37+y, 106, 89, fur)
                if !sleeping {
                    for x in stride(from: 63.0, through: 143.0, by: 16) { ellipse(x, 29+y, 24, 24, cream) }
                    for side in [49.0, 151.0] {
                        for height in stride(from: 53.0, through: 101.0, by: 16) {
                            ellipse(side, height+y, 22, 23, cream)
                            line([CGPoint(x: side+7, y: height+12+y), CGPoint(x: side+14, y: height+13+y)], dark.opacity(0.15), 1.5)
                        }
                    }
                }
                ellipse(83, 92+y, 54, 29, cream.opacity(0.7))
                // Narrow lids, sideways pupils, and asymmetric brows: THE LOOK.
                for x in [76.0, 123.0] {
                    if sleeping || blink {
                        line([CGPoint(x:x, y:79+y), CGPoint(x:x+8, y:82+y), CGPoint(x:x+17, y:79+y)], dark, 3)
                    } else if celebrating {
                        line([CGPoint(x:x, y:81+y), CGPoint(x:x+8, y:74+y), CGPoint(x:x+17, y:81+y)], dark, 3)
                    } else if mood == .idle || mood == .calling {
                        ellipse(x+2, 70+y, 18, mood == .calling ? 22 : 18, cream)
                        ellipse(x+8, 74+y, 7, mood == .calling ? 14 : 10, dark)
                    } else {
                        let eyeHeight = judging ? 9.0 : 15.0
                        ellipse(x, 74+y, 22, eyeHeight, cream)
                        ellipse(x+(judging ? 12 : 9), 74+y, 6, eyeHeight, dark)
                        line([CGPoint(x:x-1, y:73+y), CGPoint(x:x+23, y:judging ? 78+y : 74+y)], dark, 3)
                    }
                }
                if mood == .watching || judging {
                    line([CGPoint(x:76,y:judging ? 65+y : 64+y),CGPoint(x:98,y:judging ? 70+y : 62+y)],dark,3)
                    line([CGPoint(x:122,y:judging ? 62+y : 62+y),CGPoint(x:143,y:judging ? 55+y : 64+y)],dark,3)
                }
                shape([CGPoint(x:105,y:94+y),CGPoint(x:115,y:94+y),CGPoint(x:110,y:99+y)],dark)
                line([CGPoint(x:110,y:99+y),CGPoint(x:110,y:105+y)],dark,2)
                if judging {
                    line([CGPoint(x:101,y:109+y),CGPoint(x:117,y:107+y)],dark,2)
                } else {
                    line([CGPoint(x:101,y:106+y),CGPoint(x:106,y:109+y),CGPoint(x:110,y:105+y),CGPoint(x:115,y:109+y),CGPoint(x:120,y:106+y)],dark,2)
                }
                for offset in [0.0, 7.0] {
                    line([CGPoint(x:83,y:98+offset+y),CGPoint(x:63,y:94+offset*2+y)],dark.opacity(0.65),1.5)
                    line([CGPoint(x:137,y:98+offset+y),CGPoint(x:157,y:94+offset*2+y)],dark.opacity(0.65),1.5)
                }
                context.fill(Path(roundedRect: CGRect(x: 35, y: 152, width: 150, height: 17), cornerRadius: 6), with: .color(Color(red: 0.43, green: 0.32, blue: 0.24)))
                ellipse(77, 143, 23, 14, fur); ellipse(120, 143, 23, 14, fur)
                // The gavel tilts with the verdict; reduced-motion keeps it still.
                var gavel = context
                gavel.translateBy(x: 166, y: 140)
                gavel.rotate(by: .degrees(judging ? (reduceMotion ? -35 : -35 + sin(seconds*6)*8) : 18))
                gavel.fill(Path(roundedRect: CGRect(x:-3,y:-24,width:6,height:34),cornerRadius:3),with:.color(lime))
                gavel.fill(Path(roundedRect: CGRect(x:-17,y:-31,width:34,height:15),cornerRadius:4),with:.color(lime))
                if sleeping {
                    context.draw(Text("z Z").font(.system(size: 18, weight: .bold, design: .rounded)).foregroundColor(lime), at: CGPoint(x:178,y:39+y))
                } else if judging {
                    context.draw(Text("…").font(.system(size: 24, weight: .bold)).foregroundColor(lime), at: CGPoint(x:185,y:49))
                } else if mood == .calling {
                    context.draw(Text("!").font(.system(size: 24, weight: .bold)).foregroundColor(lime), at: CGPoint(x:185,y:49))
                } else if celebrating {
                    for (x,y) in [(37.0,53.0),(180.0,65.0),(110.0,14.0)] {
                        context.draw(Text("✦").font(.system(size:18)).foregroundColor(lime),at:CGPoint(x:x,y:y+bob))
                    }
                }
            }
        }
        .aspectRatio(220.0 / 184, contentMode: .fit)
        .accessibilityElement(children: .ignore).accessibilityLabel(label)
        .help(label)
    }
}
