package controllers

import play.api._
import play.api.Play.current
import play.api.mvc._

object Application extends Controller with Secured {
  
  def index = Action { implicit request =>
    Ok(views.html.overview())
  }

  def features = Action { implicit request =>
    Ok(views.html.features())
  }

  def plans = Action { implicit request =>
    Ok(views.html.plans())
  }

  def developers = TODO

  def login = TODO

  def signup = TODO

  def company = TODO

  def javascriptMessages = Action { implicit request =>
    val messages = new jsmessages.api.JsMessages
    Ok(messages(Some("window._"))).as(JAVASCRIPT)
  }

  def javascriptRoutes = Action { implicit request =>
    import routes.javascript._
    Ok(
      Routes.javascriptRouter("routes")(
        routes.javascript.Application.javascriptRoutes,
        routes.javascript.Application.javascriptValues
      )
    ).as("text/javascript")
  }

  def javascriptValues = Action { implicit request =>
    var kv: Map[String, String] = Map()
    // getOptionUser map { user =>
    //   kv += (("id" -> user.id.toString))
    //   kv += (("email" -> user.email))
    //   kv += (("name" -> user.name))
    // } getOrElse {

    // }
    Ok( views.html.javascriptValues(kv) ).as("text/javascript")
  }

}