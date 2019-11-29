//
//  FirstViewController.swift
//  betquin
//
//  Created by Juanca Sánchez on 11/6/19.
//  Copyright © 2019 Juanca Sánchez. All rights reserved.
//

import UIKit

struct Event {
    var id: String
    var homeTeam: String
    var awayTeam: String
    var middleLabel: String
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
    var dataSource:[Event] = []
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return(dataSource.count)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = Bundle.main.loadNibNamed("PartidosCell", owner: self, options: nil)?.first as! PartidosCell
        cell.homeTeam.text = dataSource[indexPath.row].homeTeam
        cell.awayTeam.text = dataSource[indexPath.row].awayTeam
        cell.middleLabel.text = dataSource[indexPath.row].middleLabel
        return cell
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
                                    homeTeam: String(item.competitors[0].name),
                                    awayTeam: String(item.competitors[1].name),
                                    middleLabel: "vs"
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
                            self.tabla.reloadData()
                        }
                    }

                    // everything is good, so we can exit
                    return
                }
            }
        }
        task.resume()
    }


}
