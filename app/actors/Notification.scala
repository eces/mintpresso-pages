package actors

import play.api._
import play.api.i18n.Messages
import play.api.Play.current
import play.api.templates._
import play.api.libs._
import play.api.libs.json._
import play.api.libs.concurrent.Akka
import akka.actor.{Actor, Props, ActorSystem}
import akka.actor.Actor._
import play.api.libs.concurrent.Execution.Implicits._
import com.typesafe.plugin._
import scala.concurrent._
import scala.concurrent.duration._
import models._

case class NewPasswordMail(username: String, email: String, codeUrl: String)
case class ConfirmationMail(username: String, email: String, codeUrl: String)

class MailActor extends Actor {
  val emailAddress = "support@mintpresso.com"
  val mail = use[MailerPlugin].email
  def receive = {
    case NewPasswordMail(name, email, codeUrl) => {
      mail.setSubject(s"Hi ${name}, here's link to change your password")
      mail.addRecipient(s"${name} <${email}>")
      mail.addFrom(s"MINTPRESSO <${emailAddress}>")
      mail.sendHtml(s"""
<html>
Hello, ${name}
<br />
You can change your password immediately by clicking this link below:
<br />
<br />
<a href="${codeUrl}">${codeUrl}</a>
<br />
<br />
Thanks.
<br />
<br />
―――
<br />
MINTPRESSO
<br />
http://mintpresso.com
<br />
This email is sent by a request of the user signed as ${email}. If you've never signed up before, ignore or please reply to us with empty body.
</html>"""
      )
    }
    case ConfirmationMail(name, email, codeUrl) => {
      mail.setSubject(s"Hi ${name}, welcome to mintpresso")
      mail.addRecipient(s"${name} <${email}>")
      mail.addFrom(s"MINTPRESSO <${emailAddress}>")
      mail.sendHtml(s"""
<html>
Nice to see you, ${name}
<br />
<br />
Mintpresso is growing up everyday and also carefully listening to your voice.
<br />
Many developers are already on active conversation so they can learn more, build faster, and earn credits as a contributor.
<br />
Please feel free to contact us. 
<br />
<br />
Click this link below to confirm your email address:
<br />
<a href="${codeUrl}">${codeUrl}</a>
<br />
<br />
Thanks.
<br />
<br />
―――
<br />
MINTPRESSO
<br />
http://mintpresso.com
<br />
This email is sent by a request of the user signed as ${email}. If you've never signed up before, ignore or please reply to us with empty body.
</html>"""
      )
    }
  }
}

class AlertActor extends Actor {
  def receive = {
    // case 예치금추가(userNo, projectId, projectName, amount) => {
    //   for {
    //     create <- MintpressoAPI("secret").addPoint("notification", "", Json.obj(
    //       "type" -> "예치금추가",
    //       "projectId" -> projectId,
    //       "projectName" -> projectName,
    //       "amount" -> amount
    //     ).toString)
    //     send <- MintpressoAPI("secret").linkWithEdge(Map(
    //       "subjectType" -> "user",
    //       "subjectId" -> userNo.toString,
    //       "verb" -> "receive",
    //       "objectType" -> "notification",
    //       "objectId" -> (create.json \ "point" \ "id").as[Long].toString 
    //     ))
    //   } yield (create.status) 
    // }
    case _ =>
  }
}

object Notification {
  val email = Akka.system.actorOf(Props[MailActor], name = "MailActor")
  val alert = Akka.system.actorOf(Props[AlertActor], name = "AlertActor")
}