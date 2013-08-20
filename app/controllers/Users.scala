package controllers

import play.api._
import play.api.i18n.Messages
import play.api.mvc._
import play.api.data.Forms._
import play.api.data._
import play.api.Play.current
import play.api.libs._
import play.api.cache._
import play.api.libs.json._
import scala.util.{Try, Success, Failure}
import scala.concurrent._
import scala.concurrent.duration._
import play.api.libs.ws.Response

import models.User
import play.api.libs.concurrent.Execution.Implicits._

object Users extends Controller with Secured {
  def signin = Action { implicit request =>
    val form = Form( tuple( "email" -> Forms.email, "password" -> nonEmptyText ) )
    form.bindFromRequest.fold (
      formWithErrors => Ok("form.empty"),
      values => {
        val (e, p) = values

        Async {
          Mintpresso(s"/user/${e}").get map { r1 =>
            if(r1.status == 200){
              val u = (r1.json \ "user").as[JsObject]
              if( (u \ "password").asOpt[String].getOrElse("") == Crypto.sign(p) ){
                val email = (u \ "$id").as[String]
                val url = email.replaceAll("[@.#]", "-")
                Redirect(routes.Pages.index(url)).withSession(
                  "no" -> (u \ "$no").as[String],
                  "email" -> email,
                  "name" -> (u \ "name").as[String],
                  "url" -> url
                )
              }else{
                Ok("user.invalid")
              }
            }else{
              Ok("user.empty")
            }
          }
        }
      }
    )    
  }

  def signout = Action { implicit request =>
    Redirect(routes.Application.index).withNewSession
  }

  def signup = Action { implicit request =>
    val form = Form( tuple( "username" -> nonEmptyText, "email" -> Forms.email, "password" -> nonEmptyText ) )
    form.bindFromRequest.fold (
      formWithErrors => Ok("form.empty"),
      values => {
        val (u, e, p) = values

        Async {
          Mintpresso(s"/user/${e}").get map { r1 =>
            if(r1.status == 404){
              Async {
                Mintpresso(s"/user").withConnection { conn =>
                  val user = Json.obj(
                    "user" -> Json.obj(
                      "$id" -> e,
                      "password" -> Crypto.sign(p),
                      "name" -> u,
                      "url" -> e.replaceAll("[@.#]", "-")
                    )
                  )
                  conn.post(user)
                }.map { r2 =>
                  if(r2.status == 201){
                    Created
                  }else{
                    Ok("try.again")
                  }
                }
              }
            }else{
              Ok("email.duplicate")
            }
          }
        }
      }
    )    
  }
}