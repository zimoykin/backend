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
                            BEGIN
                               UPDATE
                                   posts
                               SET
                                   ranking = (
                                       SELECT
                                           SUM(
                                               CASE WHEN emotions.emotion = 'like' THEN
                                                   2
                                               WHEN emotions.emotion = 'dislike' THEN
                                                   1
                                               ELSE
                                                   0
                                               END)
                                       FROM
                                           emotions
                                       WHERE
                                           emotions.blog_id = posts.id) + (
                                           SELECT
                                               COUNT(messages.id)
                                           FROM
                                               messages
                                           WHERE
                                               messages.blog_id = posts.id);
                                RETURN NEW;
                            END;
                            $function$
                                                                                
                    """).run().map{
                        database.raw("""
                    
                            CREATE TRIGGER updatemessages
                            AFTER UPDATE OR INSERT OR DELETE ON messages
                            FOR EACH ROW
                            EXECUTE PROCEDURE updatecount ();
                                                    
                    """).run().map{
                        database.raw("""
                          
                            CREATE TRIGGER updateRanking
                            AFTER UPDATE OR INSERT OR DELETE ON emotions
                            FOR EACH ROW
                            EXECUTE PROCEDURE updatecount ();
                                                    
                    """).run()}
                    }.transform(to: ())
            })
        
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(MessageModel.schema).delete().flatMap({
            let database = database as! SQLDatabase
            return database.raw("""

                            DROP TRIGGER IF EXISTS updateRanking ON emotions;
                            DROP TRIGGER IF EXISTS updatemessages ON messages;
                                                                    
                """)
                .run()
                .transform(to: ())
        })
    }
}

// check triggers
//SELECT
//    trigger_schema,
//    trigger_name
//FROM
//    information_schema.triggers
//
//
