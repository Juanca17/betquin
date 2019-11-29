//
//  SecondViewController.swift
//  betquin
//
//  Created by Juanca Sánchez on 11/6/19.
//  Copyright © 2019 Juanca Sánchez. All rights reserved.
//

import UIKit

struct Team {
    var position: String
    var teamName: String
    var points: String
}

// MARK: - Standings
struct Standings: Codable {
    let schema: String
    let standings: [Standing]

    enum CodingKeys: String, CodingKey {
        case schema, standings
    }
}

// MARK: - Standing
struct Standing: Codable {
    let tieBreakRule, type: String
    let groups: [Group]

    enum CodingKeys: String, CodingKey {
        case tieBreakRule = "tie_break_rule"
        case type, groups
    }
}

// MARK: - Group
struct Group: Codable {
    let name, id: String
    let teamStandings: [TeamStanding]

    enum CodingKeys: String, CodingKey {
        case name, id
        case teamStandings = "team_standings"
    }
}

// MARK: - TeamStanding
struct TeamStanding: Codable {
    let team: Sport
    let rank: Int
    let currentOutcome: String?
    let played, win, draw, loss: Int
    let goalsFor, goalsAgainst, goalDiff, points: Int
    let change: Int

    enum CodingKeys: String, CodingKey {
        case team, rank
        case currentOutcome = "current_outcome"
        case played, win, draw, loss
        case goalsFor = "goals_for"
        case goalsAgainst = "goals_against"
        case goalDiff = "goal_diff"
        case points, change
    }
}

// MARK: - Sport
struct Sport: Codable {
    let id, name: String
}

class SecondViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var tabla: UITableView!
    var dataSource:[Team] = []
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return(dataSource.count)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = Bundle.main.loadNibNamed("TablaGeneralCell", owner: self, options: nil)?.first as! TablaGeneralCell
        cell.position.text = dataSource[indexPath.row].position
        cell.teamName.text = dataSource[indexPath.row].teamName
        cell.points.text = dataSource[indexPath.row].points
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60.0
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        fetchTablaGeneral()
    }
    
    func fetchTablaGeneral() {
        let standingsUrl = "https://api.sportradar.us/soccer-t3/am/en/tournaments/sr:tournament:27464/standings.json?api_key=8d2297k2wtfnsxxcg4zhacse"
        let url = URL(string: standingsUrl)!
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let data = data {
                if let decodedResponse = try? JSONDecoder().decode(Standings.self, from: data) {
                    // we have good data – go back to the main thread
                    DispatchQueue.main.async {
                        // update our UI
                        if decodedResponse.standings.count > 0 {
                            if decodedResponse.standings[0].groups.count > 0 {
                                if decodedResponse.standings[0].groups[0].teamStandings.count > 0 {
                                    let tablaGeneral = decodedResponse.standings[0].groups[0].teamStandings
                                    for item in tablaGeneral {
                                        self.dataSource.append(Team(
                                            position: String(item.rank),
                                            teamName: parseTeamName(rawName: item.team.name),
                                            points: String(item.points)
                                        ))
                                    }
                                    self.tabla.reloadData()
                                }
                            }
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

func parseTeamName(rawName: String) -> String {
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

