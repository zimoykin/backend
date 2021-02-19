//
//  File.swift
//  
//
//  Created by Дмитрий on 19.02.2021.
//

import Fluent
import FluentPostgresDriver

struct CreateTriggers: Migration {
    
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
    
    
    func prepare(on database: Database) -> EventLoopFuture<Void> {
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
                                   coalesce(SUM(
                                       CASE WHEN emotions.emotion = 'like' THEN
                                          3
                                       WHEN emotions.emotion = 'dislike' THEN
                                           1
                                       ELSE
                                           0
                                       END),0)
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
