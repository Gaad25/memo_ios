//
//  StatisticsView.swift
//  memo
//
//  Created by Gabriel Gad Costa Weyers on 13/07/25.
//
// memo/Features/Statistics/StatisticsView.swift

// memo/Features/Statistics/StatisticsView.swift

import SwiftUI
import Charts

struct StatisticsView: View {
    @StateObject private var viewModel = StatisticsViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .padding()
                    } else if viewModel.subjectPerformances.isEmpty && viewModel.weeklyDistribution.allSatisfy({$0.minutes == 0}) {
                        Text("Não há dados suficientes para exibir as estatísticas. Comece a registrar suas sessões de estudo!")
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding()
                    } else {
                        // Gráfico 1: Tempo de Estudo por Matéria
                        VStack(alignment: .leading) {
                            Text("Tempo de Estudo por Matéria")
                                .font(.headline)
                            Chart(viewModel.subjectPerformances) { performance in
                                BarMark(
                                    x: .value("Matéria", performance.name),
                                    y: .value("Minutos", performance.totalMinutes)
                                )
                                // CORREÇÃO APLICADA AQUI:
                                // Agora usamos a cor específica da matéria, vinda do ViewModel.
                                .foregroundStyle(performance.color)
                            }
                            .chartYAxisLabel("Minutos")
                            .frame(height: 250)
                        }
                        .padding()
                        .background(Color(uiColor: .secondarySystemBackground))
                        .cornerRadius(12)

                        // Gráfico 2: Taxa de Acerto por Matéria (Este já estava correto)
                        VStack(alignment: .leading) {
                            Text("Taxa de Acerto por Matéria")
                                .font(.headline)
                            Chart(viewModel.subjectPerformances.filter { $0.accuracy > 0 }) { performance in
                                BarMark(
                                    x: .value("Acertos (%)", performance.accuracy * 100),
                                    y: .value("Matéria", performance.name)
                                )
                                .annotation(position: .trailing) {
                                    Text("\(Int(performance.accuracy * 100))%")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .foregroundStyle(performance.color)
                            }
                            .chartYAxis {
                                AxisMarks(position: .leading)
                            }
                            .frame(height: CGFloat(viewModel.subjectPerformances.filter { $0.accuracy > 0 }.count) * 40)
                        }
                        .padding()
                        .background(Color(uiColor: .secondarySystemBackground))
                        .cornerRadius(12)

                        // Gráfico 3: Distribuição Semanal de Estudo
                        VStack(alignment: .leading) {
                            Text("Distribuição Semanal de Estudo")
                                .font(.headline)
                            Chart(viewModel.weeklyDistribution) { day in
                                BarMark(
                                    x: .value("Dia", day.id),
                                    y: .value("Minutos", day.minutes)
                                )
                                .foregroundStyle(Color.blue.gradient)
                            }
                            .chartYAxisLabel("Minutos de Estudo")
                            .frame(height: 200)
                        }
                        .padding()
                        .background(Color(uiColor: .secondarySystemBackground))
                        .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationTitle("Estatísticas")
            .onAppear {
                Task {
                    await viewModel.fetchData()
                }
            }
        }
    }
}

struct StatisticsView_Previews: PreviewProvider {
    static var previews: some View {
        StatisticsView()
    }
}
