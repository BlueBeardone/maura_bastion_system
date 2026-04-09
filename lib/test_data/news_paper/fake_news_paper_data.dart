

import 'package:maura_bastion_system/models/news_paper/news_paper_article.dart';
import 'package:maura_bastion_system/models/news_paper/news_paper_data.dart';

String formatDate(DateTime date) {
  const monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
  return '${date.day} ${monthNames[date.month - 1]} ${date.year}'; 
}
NewspaperData getFakeNewspaperData() {
  return NewspaperData(
    newspaperName: 'Maura Weekly',
    date: formatDate(DateTime.now()),
    edition: '42',
    leadArticle: NewspaperArticle(
      title: 'Special Edition: An Interview with the Mystery Bard!',
      content:
      '''
In celebration of the opening of the Spring Fest Festival, the Sylvestris Troupe has given us a special opportunity to sit down with one of its most popular performers: the Mystery Bard.

Mystery Bard: Hi everyone! I`m so glad I`ve been given this opportunity to speak with you all! You have no idea how much I`m smiling right now.

Interviewer: Thank you for this opportunity! Shall we begin with the interview?

Mystery Bard: Of course! Ask away!

Interviewer: Let`s start with your career where did you train and who mentored you along the way?

Mystery Bard: I was trained by Lady Saphira, the Storyteller. She has an incredible amount of experience and a truly beautiful voice. I was already fairly skilled with a few instruments, but she really helped me improve my singing. I deeply enjoyed my time with the Sylvestris Troupe.

Interviewer: And now you`re pursuing a solo career, is that right?

Mystery Bard: That`s correct. After my popularity began to grow, I decided to follow my own path and see more of the world. That said, I still perform with the troupe from time to time like I will be doing for the upcoming Spring Fest.

Interviewer: What inspired you to become a bard?

Mystery Bard: I`ve always loved singing and creating music. It means so much to me that people enjoy and listen to my songs. I feel incredibly blessed to have so many fans, and now I get to travel and meet them!

Interviewer: Your stage name the Mystery Bard is quite intriguing. Where did it come from?

Mystery Bard: Well… I`m quite shy, and I think that`s part of the charm, isn`t it? By being no one, I can be anyone for my fans! Though for me personally, it`s about the music that`s what should be in the spotlight, not me.

Interviewer: Is there anything else you`d like to say to your fans before we wrap up?

Mystery Bard: Yes! I want to thank everyone for their support. I wouldn`t be where I am today without their love it truly means the world to me. I`ll be performing at Spring Fest on the main stage I am very excited to be able to play in Maura again! so if are in the area please come and visit!

And that concludes our interview. We hope this has helped you get to know the Mystery Bard a little better though she will no doubt remain an enigma. If you find yourself in Maura this coming week, we highly recommend visiting the Spring Fest Festival. Be quick, though tickets for her concert are already running out.
      ''',
      author: 'Nanox',
      imageUrl: null, // placeholder will be shown
    ),
    otherArticles: [
      NewspaperArticle(
        title: 'MAURA SHOWS ITS POWER',
        content:
        """
After a brutal, bone-jarring fight between the ancient sentinel of the Durn pass and the Mauran A-rankers, the clash finally came to an end. Against all early reports that suggested the merchant association`s private army had been utterly devastated, it was Maura that stood victorious over the creature`s broken form.

These brave heroes are:

Leto
Kethryn
Draco

Three Mauran A-rankers, fighting as a single coiled fist, beat back a creature that was said to be unstoppable, a guardian that had, only days before, slaughtered an entire private military force equivalent to their own rank. Maura may be stretched thin across multiple fronts, but their combat prowess still stands as a pillar to lean on. Or is it that the Merchant Association simply faked their documents about how strong their private military truly was?

Either way, the pass is now open, and the name of Maura rings louder than ever.

Three cheers for the good people of Maura!
""",
        author: 'Anonymous',
        imageUrl: null,
      ),
      NewspaperArticle(
        title: "MERCHANT ASSOCIATION'S PRIVATE MILITARY ANNIHILATED BY UNKNOWN GUARDIAN",
        content:
        """
A heavily armed private military force, contracted by the merchant association to secure a vital trade route through the rugged pass at Durn, has been virtually wiped out in a single, one sided engagement. Sources confirm that the soldiers, assessed as being equivalent to A-rank Adventurers in Maura, were routed with catastrophic losses by a solitary entity that appears to guard the passage.

The disaster unfolded late yesterday evening as the association`s convoy escorted by over 20 elite troops, armored wagons, and support mages attempted to transit the narrow defile known locally as the Flat Crossing. The few survivors speaks of a construct capable of mass destruction guarding the road. 

Survivors tell of complete and utter defeat. With not much of casualty nor scratch on the enemy force. There is talks that the merchant association will have to bend the knee and accept Maura's help in taking out this enemy.
""",
        author: 'Anonymous',
        imageUrl: null,
      ),
      NewspaperArticle(
        title: "Unique Magical cave system collapses - hundreds of croak's found dead in the rubble - one of a kind Fish species eradicated.",
        content:
          """
Due to yet mysterious circumstances a cave on Parsius with incredible healing properties  fell into itself tragically.
The community of croak's within Maura mourn the lesser known tribe as if it were from their own tribe.

It also seemed to have let a dangerous large toad into the wild habitats of Parsius for which they were not prepared.

Disaster struck that day, magical forensics found a druid message left behind in the inner sanctum that reads the following:

To forget your roots is to wither and die.
To value creation takes sacrifice
To bow down to gods is weakness
To bow down to nature is to forgive yourself
""",
        author: 'Cupcake',
        imageUrl: null,
      ),
    ],
  );
}