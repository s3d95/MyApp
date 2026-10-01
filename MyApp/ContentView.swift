import SwiftUI

struct ContentView: View {
    @State private var taps = 0

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.10, green: 0.12, blue: 0.30),
                                    Color(red: 0.35, green: 0.15, blue: 0.55)],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                Image("MainImage")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 260, height: 260)
                    .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                    .shadow(color: .black.opacity(0.4), radius: 20, y: 10)

                Text("أهلاً وسهلاً 👋")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("التطبيق شغّال تمام على الآيفون")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.8))

                Spacer()

                Button {
                    taps += 1
                } label: {
                    Text(taps == 0 ? "اضغط هون" : "ضغطت \(taps) مرّة")
                        .font(.headline)
                        .foregroundColor(Color(red: 0.25, green: 0.12, blue: 0.45))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.white)
                        .clipShape(Capsule())
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
            .padding()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View { ContentView() }
}
