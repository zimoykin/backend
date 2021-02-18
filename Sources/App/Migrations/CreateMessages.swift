import Fluent
import FluentPostgresDriver

struct CreateMessages: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        
        return database.schema(MessageModel.schema)
            .id()
            .field("message",       .string, .required)
            .field("user_id",       .uuid, .references(UserModel.schema, .id, onDelete: .cascade), .required)
            .field("blog_id",       .uuid, .references(BlogModel.schema, .id, onDelete: .cascade))
            .field("to_user_id",    .uuid, .references(BlogModel.schema, .id, onDelete: .cascade))
            .field("created_at",    .datetime)
            .field("updated_at",    .datetime)
            .create().flatMap({
                let database = database as! SQLDatabase
                return database.raw("""

                          CREATE OR REPLACE FUNCTION public.updatecount ()
                              RETURNS TRIGGER
                              LANGUAGE plpgsql
                              AS $function$
                          BEGIN UPDATE posts
                              SET ranking = OLD.ranking + 1;
                              RETURN NEW;
                          END;
                          $function$;
                                                    
                    """).run().map{
                        database.raw("""

                            CREATE TRIGGER updatemessages
                            AFTER UPDATE ON messages
                            FOR EACH ROW
                            EXECUTE PROCEDURE updatecount ();
                                                    
                    """).run()
                    }.transform(to: ())
            })
        
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(MessageModel.schema).delete()
    }
}
