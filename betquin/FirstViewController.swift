//
//  FirstViewController.swift
//  betquin
//
//  Created by Juanca Sánchez on 11/6/19.
//  Copyright © 2019 Juanca Sánchez. All rights reserved.
//

import UIKit

struct SectionEvent {
    var scheduled: String
    var eventList: [Event]
}

struct Event {
    var id: String
    var homeTeam: String
    var awayTeam: String
    var middleLabel: String
    var scheduled: String
}

// MARK: - Schedule
struct Schedule: Codable {
    let schema: String
    var sportEvents: [SportEvent]

    enum CodingKeys: String, CodingKey {
        case schema
        case sportEvents = "sport_events"
    }
}

// MARK: - Results
struct Results: Codable {
    let schema: String
    let results: [Result]

    enum CodingKeys: String, CodingKey {
        case schema, results
    }
}

// MARK: - Result
struct Result: Codable {
    let sportEvent: SportEvent
    let sportEventStatus: SportEventStatus

    enum CodingKeys: String, CodingKey {
        case sportEvent = "sport_event"
        case sportEventStatus = "sport_event_status"
    }
}

// MARK: - SportEvent
struct SportEvent: Codable {
    let id: String
    let scheduled: String
    let competitors: [Competitor]

    enum CodingKeys: String, CodingKey {
        case id, scheduled
        case competitors
    }
}

// MARK: - SportEventStatus
struct SportEventStatus: Codable {
    let homeScore, awayScore: Int

    enum CodingKeys: String, CodingKey {
        case homeScore = "home_score"
        case awayScore = "away_score"
    }
}

// MARK: - Competitor
struct Competitor: Codable {
    let id, name: String
    let qualifier: Qualifier

    enum CodingKeys: String, CodingKey {
        case id, name
        case qualifier
    }
}

enum Qualifier: String, Codable {
    case away = "away"
    case home = "home"
}


class FirstViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var tabla: UITableView!
    var sectionDataSource:[SectionEvent] = []
    var dataSource:[Event] = []
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sectionDataSource[section].eventList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = Bundle.main.loadNibNamed("PartidosCell", owner: self, options: nil)?.first as! PartidosCell
        cell.homeTeam.text = sectionDataSource[indexPath.section].eventList[indexPath.row].homeTeam
        cell.awayTeam.text = sectionDataSource[indexPath.section].eventList[indexPath.row].awayTeam
        cell.middleLabel.text = sectionDataSource[indexPath.section].eventList[indexPath.row].middleLabel
        return cell
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sectionDataSource.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionDataSource[section].scheduled
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60.0
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        fetchPartidos()
    }
    
    func fetchPartidos() {
        let scheduleUrl = "https://api.sportradar.us/soccer-t3/am/en/tournaments/sr:tournament:27464/schedule.json?api_key=8d2297k2wtfnsxxcg4zhacse"
        let url = URL(string: scheduleUrl)!
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let data = data {
                if let decodedResponse = try? JSONDecoder().decode(Schedule.self, from: data) {
                    // we have good data – go back to the main thread
                    DispatchQueue.main.async {
                        // update our UI
                        if decodedResponse.sportEvents.count > 0 {
                            var agenda = decodedResponse.sportEvents
                            agenda.reverse()
                            for item in agenda {
                                self.dataSource.append(Event(
                                    id: item.id,
                                    homeTeam: parseTeamName2(rawName: String(item.competitors[0].name)),
                                    awayTeam: parseTeamName2(rawName: String(item.competitors[1].name)),
                                    middleLabel: parseMatchTime(dateString: item.scheduled),
                                    scheduled: parseDate(dateString: item.scheduled)
                                ))
                            }
                            self.fetchResults()
                        }

                    }

                    // everything is good, so we can exit
                    return
                }
            }
        }
        task.resume()
    }
    
    func fetchResults() {
        let scheduleUrl = "https://api.sportradar.us/soccer-t3/am/en/tournaments/sr:tournament:27464/results.json?api_key=8d2297k2wtfnsxxcg4zhacse"
        let url = URL(string: scheduleUrl)!
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let data = data {
                if let decodedResponse = try? JSONDecoder().decode(Results.self, from: data) {
                    // we have good data – go back to the main thread
                    DispatchQueue.main.async {
                        // update our UI
                        if decodedResponse.results.count > 0 {
                            var resultados = decodedResponse.results
                            resultados.reverse()
                            
                            var i = 0 // resultados index
                            var j = 0 // datasource index
                            while (i < resultados.count) && (j < self.dataSource.count) {
                                if resultados[i].sportEvent.id == self.dataSource[j].id {
                                    self.dataSource[j].middleLabel =
                                        String(resultados[i].sportEventStatus.homeScore) +
                                        " - " +
                                        String(resultados[i].sportEventStatus.awayScore)
                                    i += 1
                                }
                                j += 1
                            }
                            self.groupSectionEvents()
                        }
                    }

                    // everything is good, so we can exit
                    return
                }
            }
        }
        task.resume()
    }
    
    func groupSectionEvents() {
        var index: String
        var i = 0
        if self.dataSource.count > 0 {
            index = self.dataSource[0].scheduled
            self.sectionDataSource.append(SectionEvent(scheduled: index, eventList: []))
            for item in self.dataSource {
                if index == item.scheduled {
                    self.sectionDataSource[i].eventList.append(item)
                } else {
                    index = item.scheduled
                    self.sectionDataSource.append(SectionEvent(scheduled: index, eventList: [item]))
                    i += 1
                }
            }
        }
        self.tabla.reloadData()
    }


}

func parseDate(dateString: String) -> String {
    let dateFormatterGet = DateFormatter()
    dateFormatterGet.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"

    let dateFormatterPrint = DateFormatter()
    dateFormatterPrint.dateFormat = "EEEE, d MMMM yyyy"
    
    if let date = dateFormatterGet.date(from: dateString) {
        return dateFormatterPrint.string(from: date)
    } else {
       return dateString
    }
}

func parseMatchTime(dateString: String) -> String {
    let dateFormatterGet = DateFormatter()
    dateFormatterGet.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"

    let dateFormatterPrint = DateFormatter()
    dateFormatterPrint.dateFormat = "HH:00"
    
    if let date = dateFormatterGet.date(from: dateString) {
        return dateFormatterPrint.string(from: date)
    } else {
       return dateString
    }
}

func parseTeamName2(rawName: String) -> String {
    switch rawName {
    case "Club Santos Laguna":
        return "Santos"
    case "Club Leon":
        return "León"
    case "Tigres UANL":
        return "Tigres"
    case "Queretaro FC":
        return "Querétaro"
    case "CF America":
        return "América"
    case "CA Monarcas Morelia":
        return "Morelia"
    case "CF Monterrey":
        return "Monterrey"
    case "CF Pachuca":
        return "Pachuca"
    case "Guadalajara Chivas":
        return "Chivas"
    case "Xolos de Tijuana":
        return "Tijuana"
    case "Pumas Unam":
        return "Pumas"
    case "Atlas FC":
        return "Atlas"
    case "FC Juarez":
        return "Juárez"
    case "Deportivo Toluca FC":
        return "Toluca"
    case "Puebla FC":
        return "Puebla"
    case "Tiburones Rojos de Veracruz":
        return "Veracruz"
    default:
        return rawName
    }
}
