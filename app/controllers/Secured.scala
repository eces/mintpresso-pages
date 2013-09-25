package controllers

import play.api._
import play.api.mvc._
import play.api.data.Forms._
import play.api.data._
import play.api.Play.current
import play.api.libs._

import models.User

trait Secured {
  def getUser(implicit request: RequestHeader): User = {
    User(
      request.session.get("email").getOrElse(""),
      request.session.get("no").getOrElse("0").toLong,
      "",
      request.session.get("email").getOrElse(""),
      request.session.get("name").getOrElse(""),
      ""
    )
  }
  def getOptionUser(implicit request: RequestHeader): Option[User] = {
    request.session.get("no").map { no =>
      Some(getUser)
    } getOrElse {
      None
    }
  }
  def getUrl(implicit request: RequestHeader): String = {
    request.session.get("url").getOrElse("")
  }
  def signin(implicit request: RequestHeader): Boolean = {
  	request.session.get("no").map { no =>
  	  true
  	} getOrElse {
  	  false
  	}
  }
  def Signed(f: Request[AnyContent] => User => Result) = Action { implicit request =>
    if(signin){
      f(request)(getUser)
    }else{
      Results.Redirect(routes.Application.signin).flashing(
        "msg" -> "Permission required",
        "redirect.url" -> request.path
      )
    }
  }

  def SignedUrl(url: String)(f: Request[AnyContent] => User => Result) = Action { implicit request =>
    if(signin){
      if( request.session.get("url").getOrElse("") == url){
        f(request)(getUser)
      }else{
        Results.Redirect(routes.Application.signin).flashing(
          "msg" -> s"Permission override required. Currently signed as ${getUser.email}.",
          "redirect.url" -> request.path,
          "override" -> "true"
        )
      }
    }else{
      Results.Redirect(routes.Application.signin).flashing(
        "msg" -> "Permission required",
        "redirect.url" -> request.path
      )
    }
  }

  def JsonAction(url: String)(f: Request[play.api.libs.json.JsValue] => User => Result) = Action(play.api.mvc.BodyParsers.parse.json) { implicit request =>
    if(signin){
      if( request.session.get("url").getOrElse("") == url){
        f(request)(getUser)
      }else{
        Results.Redirect(routes.Application.signin).flashing(
          "msg" -> s"Permission override required. Currently signed as ${getUser.email}.",
          "redirect.url" -> request.path,
          "override" -> "true"
        )
      }
    }else{
      Results.Redirect(routes.Application.signin).flashing(
        "msg" -> "Permission required",
        "redirect.url" -> request.path
      )
    }
  }

  def FormDataAction(url: String)(f: Request[play.api.mvc.MultipartFormData[play.api.libs.Files.TemporaryFile]] => User => Result) = Action(play.api.mvc.BodyParsers.parse.multipartFormData) { implicit request =>
    if(signin){
      if( request.session.get("url").getOrElse("") == url){
        f(request)(getUser)
      }else{
        Results.Redirect(routes.Application.signin).flashing(
          "msg" -> s"Permission override required. Currently signed as ${getUser.email}.",
          "redirect.url" -> request.path,
          "override" -> "true"
        )
      }
    }else{
      Results.Redirect(routes.Application.signin).flashing(
        "msg" -> "Permission required",
        "redirect.url" -> request.path
      )
    }
  }

}