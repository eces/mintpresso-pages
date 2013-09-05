package controllers

import play.api._
import play.api.Play.current
import play.api.mvc._
import play.api.libs._
import play.api.i18n.Messages

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

  def signin = Action { implicit request =>
    getOptionUser map { user =>
      flash.get("override") match {
        case Some("true") =>
          Ok(views.html.login()).flashing(
            "request_url" -> flash.get("request.url").getOrElse(""),
            "override" -> "true"
          )
        case _ =>
          Redirect(routes.Pages.account(getUrl, ""))
      }
    } getOrElse {
      Ok(views.html.login())
    }
  }

  def changePassword(code: Option[String]) = Action { implicit request =>
    code map { c =>
      val parts = Crypto.decryptAES(c).split("__MINT__")
      val no = parts(0)
      val email = parts(1)
      Ok(views.html.changePassword(c, email))
    } getOrElse {
      Redirect(routes.Application.signin).flashing(
        "error" -> Messages("reset.code.invalid")
      )
    }
  }

  def signup = TODO

  def faq = TODO

  def documentation = Action { implicit request =>
    Ok(views.html.documentation())
  }

  def terms = Action { implicit request =>
    Ok(views.html.terms())
  }

  def privacy = Action { implicit request =>
    Ok(views.html.privacy())
  }

  def security = Action { implicit request =>
    Ok(views.html.security())
  }

  def status = Action { implicit request =>
    Ok(views.html.status())
  }

  def about = Action { implicit request =>
    Ok(views.html.about())
  }

  def javascriptMessages = Action { implicit request =>
    val messages = new jsmessages.api.JsMessages
    Ok(messages(Some("window._"))).as(JAVASCRIPT)
  }

  def javascriptRoutes = Action { implicit request =>
    import routes.javascript._
    Ok(
      Routes.javascriptRouter("routes")(
        routes.javascript.Users.signup,
        routes.javascript.Users.signin,
        routes.javascript.Users.findPassword,
        routes.javascript.Pages.account,
        routes.javascript.Pages.accountUsage,
        routes.javascript.Pages.accountPlansAndBilling,
        routes.javascript.Pages.accountApiKey,
        routes.javascript.Pages.accountApiKeyUpdate,
        routes.javascript.Pages.accountApiKeyDelete,
        routes.javascript.Pages.collect,
        routes.javascript.Pages.collectSearch,
        routes.javascript.Pages.collectImport,
        routes.javascript.Pages.collectExport,
        routes.javascript.Pages.order,
        routes.javascript.Pages.orderStatus,
        routes.javascript.Pages.orderStatusPause,
        routes.javascript.Pages.orderStatusStart,
        routes.javascript.Pages.orderDelete,
        routes.javascript.Pages.orderAdd,
        routes.javascript.Pages.orderAddVerb,
        routes.javascript.Pages.orderAddType,
        routes.javascript.Pages.orderAddUpdate,
        routes.javascript.Pages.pickup,
        routes.javascript.Pages.support,
        routes.javascript.Application.signin,
        routes.javascript.Application.javascriptRoutes,
        routes.javascript.Application.javascriptValues
      )
    ).as("text/javascript")
  }

  def javascriptValues = Action { implicit request =>
    var kv: Map[String, String] = Map()
    getOptionUser map { user =>
      kv += (("id" -> user.id.toString))
      kv += (("email" -> user.email))
      kv += (("name" -> user.name))
      kv += (("no" -> user.no.toString))
      kv += (("url" -> request.session.get("url").getOrElse("")))
      kv += (("server" -> Play.configuration.getString("mintpresso.server").getOrElse("http://localhost:15200") ))
    }
    Ok( views.html.javascriptValues(kv) ).as("text/javascript")
  }

}