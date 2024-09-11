import SwiftUI

struct HeightSelector: View {
    @EnvironmentObject var poleSettings: PoleSettings
    @State private var input: String = ""
    
    var body: some View {
        VStack {
            TextField("Enter Height", text: $input)
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .frame(width: 300)
                .keyboardType(.decimalPad)
                .onChange(of: input) { newValue in
                    let filtered = newValue.filter { "0123456789.".contains($0) }
                    
                    if filtered != newValue {
                        self.input = filtered
                    }
                    
                    // Update poleSettings.height if input is a valid number
                    if let heightValue = Float(filtered) {
                        poleSettings.height = heightValue
                    }
                }
            
            Text("Current Height: \(poleSettings.height, specifier: "%.2f")")
                .padding()
        }
        .padding()
    }
}

#Preview {
    HeightSelector().environmentObject(PoleSettings())
}
