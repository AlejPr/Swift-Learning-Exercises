import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var logs: [WaterLog]
    
    @State var selectedTab: Int = 1
    var totalHydration: CGFloat {
        return CGFloat(logs.reduce(into: 0) { $0 += $1.amountML })
    }
    var progress: CGFloat {
        return totalHydration / 2000
    }
        
    var body: some View {
        NavigationView {
            TabView(selection: $selectedTab) {
                todayView
                    .tabItem { Label("Today", systemImage: "waterbottle.fill") }
                    .tag(1)

                settingsView
                    .tabItem { Label("Settings", systemImage: "gear") }
                    .tag(2)
     
            }
            .navigationTitle(selectedTab == 1 ? "Hydration" : "Settings")
        }
    }
    
    //MARK: - Today View
    var todayView: some View {
        VStack(spacing: 25) {
            
            ZStack {
                Color.secondary.opacity(0.02)
                    .cornerRadius(15)

                HStack {
                    CustomProgressView(progress: progress)
                        .frame(width: 90, height: 90)
                        .padding(.trailing, 25)
                    
                    VStack {
                        HStack(alignment: .bottom, spacing: 2) {
                            Text("\(Int(totalHydration))")
                                .font(.system(size: 30, weight: .bold))
                            Text("ml")
                                .padding(.bottom, 4)
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(Color.black.opacity(0.6))
                        }
                        Text("of \("2000ml") daily goal")
                            .padding(.bottom, 4)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(Color.black.opacity(0.6))
                    }
                }
            }
            .frame(height: 180)
            .overlay {
                RoundedRectangle(cornerRadius: 20.0)
                    .stroke(.gray.opacity(0.3), lineWidth: 1)
            }
            .padding(.horizontal, 25)

            HStack(spacing: 20) {
                HydrationButton(action: { addHydration(value: 250) }, amount: 250)
                HydrationButton(action: { addHydration(value: 500) }, amount: 500)
            }
            .padding(.horizontal, 25)
            
            if logs.isEmpty {
                VStack {
                    Image(systemName: "drop")
                        .foregroundStyle(.gray.opacity(0.5))
                        .font(.system(size: 45, weight: .medium))
                    Text("No entries today")
                        .foregroundStyle(.gray.opacity(0.75))
                        .font(.system(size: 20, weight: .medium))

                    Text("Add water to start tracking")
                        .foregroundStyle(.gray.opacity(0.5))
                        .font(.system(size: 18, weight: .medium))

                    Spacer()
                }
                .padding(.top, 70)
            }
            
            else {
                List {
                    Section {
                        Text("Today's Entries")
                            .foregroundColor(.black)
                            .font(.system(size: 20, weight: .medium))
                            .listRowInsets(EdgeInsets())
                            .listSectionSeparator(.hidden)
                            .padding(.leading, 15)
                    }
                    Section {
                        ForEach(logs) { log in
                            ListRowView(log: log)
                        }
                    }
                }
                .padding(.horizontal, 25)
                .listStyle(.plain)
            }
            
            
        }
    }
    
    //MARK: - Settings
    var settingsView: some View {
        Text("Settings")
    }
    
    
    //MARK: - Logic
    private func addHydration(value: Int) {
        withAnimation {
            let newLog = WaterLog(amountML: value, source: "iPhone")
            modelContext.insert(newLog)
            do { try modelContext.save() }
            catch { print("Could not save new waterlog entry! \(error)") }
        }
    }

    
}


//MARK: - Reusable structs
extension ContentView {
    
    
    private struct ListRowView: View {
        let log: WaterLog
        var df: DateFormatter {
            let df = DateFormatter()
            df.dateFormat = "hh:mm a"
            return df
        }
        
        var body: some View {
            HStack {
                ZStack {
                    Circle()
                        .foregroundStyle(.blue.opacity(0.25))
                    Image(systemName: "drop.fill")
                        .foregroundStyle(.blue)
                }
                .frame(height: 40)
                
                VStack(alignment: .leading) {
                    Text("\(log.amountML)ml")
                        .font(.system(size: 16, weight: .bold))
                    Text(df.string(from: log.timestamp))
                }
            }
        }
    }
    
    private struct HydrationButton: View {
        let action: () -> ()
        let amount: Int
        
        var body: some View {
            Button { action() }
            label: {
                ZStack {
                    Color.blue
                    HStack {
                        Label("\(amount)ml", systemImage: "drop.fill")
                            .foregroundStyle(Color.white)
                            .font(.system(size: 18, weight: .medium))
                    }
                }
                .frame(height: 50)
                .cornerRadius(15)
            }
        }
        
    }
    
    
    private struct CustomProgressView: View {
        
        let progress: CGFloat
        
        var body: some View {
            ZStack {
                Text(String(format: "%.f%%", progress * 100))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.blue)
                Circle()
                    .stroke(
                        Color.gray.opacity(0.75),
                        lineWidth: 12
                    )
                Circle()
                    .trim(from: 0.0, to: progress)
                    .stroke(
                        Color.blue,
                        style: StrokeStyle(
                            lineWidth: 12,
                            lineCap: .round
                        )
                    )
                    .rotationEffect(.degrees(-90))
                
            }
        }
        
    }
    
}

#Preview() {
    ContentView(selectedTab: 1)
        .modelContainer(SwiftDataPersistenceService(inMemory: true).container)
}

