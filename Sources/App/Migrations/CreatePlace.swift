import Fluent
import Foundation

struct CreatePlace: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(Place.schema)
            .id()
            .field("title",         .string, .required)
            .unique(on: "title")
            .field("description",   .string, .required)
            .field("latitude",      .double, .required)
            .field("longitude",     .double, .required)
            .field("country_id",    .uuid,   .references(Country.schema, .id))
            .create().flatMap({ _ in
                
                let italy = Country(title: "Italy", description: "Italy, EU")
                let amalfi = italy.save(on: database).map({
                    let amalfi = Place(title: "Amalfi",
                                       description: "Amalfi",
                                       latitude: 40.6349,
                                       longitude: 14.6024,
                                       country_id: italy.id! )
                    _ = amalfi.save(on: database)
                    
                })
                
                
                let france = Country(title: "France", description: "France, EU")
                let strasbourg = france.save(on: database).map({
                    let strasbourg = Place(title: "Strasbourg",
                                       description: "Strasbourg",
                                       latitude: 48.573405,
                                       longitude: 7.752111,
                                       country_id: france.id! )
                    _ = strasbourg.save(on: database)
            
                })

                let usa = Country(title: "Usa", description: "United states of America")
                let veniceBeach = usa.save(on: database).map({
                    let veniceBeach = Place(title: "Venice beach",
                                       description: "California",
                                       latitude: 37.4799417,
                                       longitude: -122.449833,
                                       country_id: usa.id! )
                    _ = veniceBeach.save(on: database)
                })
                
                let japan = Country(title: "Japan", description: "Japan")
                let tokyo = japan.save(on: database).map({
                    let tokyo = Place(title: "Tokyo",
                                       description: "Japan",
                                       latitude: 35.652832,
                                       longitude: 139.839478,
                                       country_id: japan.id! )
                    _ = tokyo.save(on: database)
                })
                
                return amalfi.and(strasbourg.and(veniceBeach.and(tokyo))).transform(to: ())

            })
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(Place.schema).delete()
    }
}
